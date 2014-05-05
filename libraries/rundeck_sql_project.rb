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
      %w(mailutils sharutils).each do |pkg|
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
          rundeck_job job_name do
            parent new_resource
            source "#{schedule}.yml.erb"
            cookbook 'rundeck-sql'
            # TODO: probably should set the connection settings via resource
            options(
                :commands => [
                    %Q(psql --dbname=#{sql_conn['database']} -U #{sql_conn['username']} -h #{node['postgres']['live']['slave']}
                       -f #{Shellwords.escape(sql_file)} > /tmp/#{name}-#{job_name}.csv),
                    %Q(cat /tmp/#{name}-#{job_name}.csv),
                    %Q{(echo "See attached.";
                          uuencode /tmp/#{name}-#{job_name}.csv /tmp/#{name}-#{job_name}.csv) |
                        mailx -s 'Review-query-#{name}-#{job_name}.csv' #{new_resource.sql_success_email} }
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
