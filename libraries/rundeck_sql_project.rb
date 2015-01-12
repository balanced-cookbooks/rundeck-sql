#
# Author:: Mahmoud Abdelkader <mahmoud@balancedpayments.com>
#
# Copyright 2014, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'shellwords'

class Chef
  class Resource::RundeckSqlProject < Resource::RundeckProject
    attribute(:sql_repository, kind_of: String, default: lazy { node['rundeck-sql']['repository'] }, required: true)
    attribute(:sql_revision, kind_of: String, default: lazy { node['rundeck-sql']['revision'] })
    attribute(:sql_failure_email, kind_of: String, default: lazy { node['rundeck-sql']['failure_email'] })
    attribute(:sql_failure_url, kind_of: String, default: lazy { node['rundeck-sql']['failure_url'] })
    attribute(:sql_success_email, kind_of: String, default: lazy { node['rundeck-sql']['success_email'] })
    attribute(:sql_success_url, kind_of: String, default: lazy { node['rundeck-sql']['success_url'] })
    attribute(:sql_report_email_map, kind_of: String, default: lazy { node['rundeck-sql']['report_email_map'] })
    attribute(:sql_connection, kind_of: Hash, required: true)
    attribute(:sql_globs, kind_of: Array, required: true)
    attribute(:sql_remote_directory, kind_of: String)     # For debugging, use remote_directory instead of git, set to the name of the cookbook

    def sql_target_destination
      ::File.join(project_path, 'sql')
    end

  end

  class Provider::RundeckSqlProject < Provider::RundeckProject

    def action_enable
      super
      notifying_block do
        clone_sql_repository
      end
      create_sql_jobs
    end

    private

    def write_project_config
      create_node_source
      r = super
      install_postgres
      ensure_mail
      r
    end

    def create_node_source
      rundeck_sql_node_source new_resource.name do
        parent new_resource
      end
    end

    def ensure_mail
      include_recipe 'postfix'
      %w(mailutils sharutils bsd-mailx).each do |pkg|
        package pkg
      end
    end

    def install_postgres
      include_recipe 'balanced-postgresql::client'
    end

    def create_virtualenv
      python_virtualenv new_resource.sql_virtualenv_path do
        owner 'root'
        group 'root'
      end
    end

    def clone_sql_repository
      if new_resource.sql_remote_directory
        remote_directory new_resource.sql_target_destination do
          user 'root'
          group 'root'
          source new_resource.sql_repository
          cookbook new_resource.sql_remote_directory
          purge true
        end
      else
        create_ssh_directory
        write_ssh_config

        include_recipe 'git'
        git new_resource.sql_target_destination do
          user 'root'
          group 'root'
          repository new_resource.sql_repository
          revision new_resource.sql_revision
          action :sync
        end
      end
    end

    def create_ssh_directory
      directory '/root/.ssh' do
        action :create
      end
    end

    def write_ssh_config
      file '/root/.ssh/deploy' do
        content citadel['deploy_key/deploy.pem']
        mode '400'
      end

      template '/root/.ssh/config' do
        source 'ssh_config.erb'
        cookbook 'rundeck-sql'
        owner 'root'
        group 'root'
        mode '400'
        variables(
            :ssh_identity_file => '/root/.ssh/deploy'
        )
      end
    end

    def create_sql_jobs
      parse_sql_tasks.each_pair do |schedule, sql_files|
        sql_files.each do |sql_file|
          name = new_resource.name
          sql_conn = new_resource.sql_connection
          sql_file = ::File.absolute_path(sql_file, new_resource.sql_target_destination)
          job_name = ::File.basename(sql_file).gsub(/\s+/, '_')
          Chef::Log.info("Converting #{sql_file} to #{job_name}")

          report_file_out_name = "#{name}-#{job_name}.csv"
          report_email_to = new_resource.sql_success_email
          report_email_subject = "Review-query-#{name}-#{job_name}.csv"
          report_email_body = 'See attached.'
          report_email_from = nil
          report_email_bcc = nil

          # For this particular file, did we override the recipient destinations?
          if new_resource.sql_report_email_map.has_key?(::File::basename(sql_file))
            report = new_resource.sql_report_email_map[::File::basename(sql_file)]
            report_email_to = report.fetch('to', report_email_to)
            report_email_subject = report.fetch('subject', report_email_subject)
            report_email_body = report.fetch('body', report_email_body)
            report_email_from = report.fetch('from', report_email_from)
            report_email_bcc = report.fetch('bcc', report_email_bcc)
          end

          mail_cmd = build_mail_cmd(
              report_email_to, report_email_subject, report_email_body,
              :report_email_from => report_email_from,
              :report_email_bcc => report_email_bcc,
              :report_email_attachment => "/tmp/#{report_file_out_name}"
          )

          rundeck_job job_name do
            parent new_resource
            source "#{schedule}.yml.erb"
            cookbook 'rundeck-sql'
            # TODO: probably should set the connection settings via resource
            options(
                :commands => [
                    %Q(psql --dbname=#{sql_conn['database']} \
                            -U #{sql_conn['username']}  \
                            -h #{node['postgres']['live']['slave']} \
                            -f #{Shellwords.escape(sql_file)} > /tmp/#{report_file_out_name}),
                    %Q(cat /tmp/#{report_file_out_name}),
                    mail_cmd,
                ],
                :failure_recipient => new_resource.sql_failure_email,
                :failure_notify_url => new_resource.sql_failure_url,
                :success_recipient => new_resource.sql_success_email,
                :success_notify_url => new_resource.sql_success_url
            )
          end
        end
      end
    end

    def build_mail_cmd(to, subject, body, options={})
      bcc = options.fetch(:report_email_bcc, nil)
      from = options.fetch(:report_email_from, nil)
      attachment = options.fetch(:report_email_attachment, nil)

      to = to.join(',') if to.kind_of?(Array)
      bcc = bcc.join(',') if bcc.kind_of?(Array)
      body = Shellwords.escape(body)
      subject = Shellwords.escape(subject)
      # $ echo "something" | mailx -s "subject" -b bcc_user@some.com -c cc_user@some.com  -r sender@some.com recipient@example.com
      from = Shellwords.escape("From: no-reply <#{from}>") unless from.nil?

      cmd = []
      if attachment.nil?
        cmd << %Q[echo "#{body}" | ]
      else
        cmd << %Q[(echo "#{body}"; uuencode #{attachment} #{attachment}) |]
      end
      cmd << 'mailx'
      cmd << %Q[-a '#{from}'] unless from.nil?
      cmd << %Q[-b '#{bcc}'] unless bcc.nil?
      cmd << %Q[-s "#{subject}"]
      cmd << to

      cmd.join(' ')
    end

    def parse_sql_tasks
      tasks = {'monthly' => [], 'daily' => [], 'weekly' => []}
      new_resource.sql_globs.each do |glob_expr|
        path = ::File.join(new_resource.sql_target_destination, glob_expr)
        files = Dir.glob(path)
        Chef::Log.info("Globbed: #{files} from expr: #{glob_expr} @ #{path}")
        files.each do |fname|
          tasks.keys.each do |key|
            if fname =~ Regexp.new(key)
              tasks[key] << fname
            end
          end
        end
      end
      Chef::Log.info("Populated tasks: #{tasks}")
      tasks
    end

  end
end
