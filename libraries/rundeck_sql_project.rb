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

class Chef
  class Resource::RundeckSqlProject < Resource::RundeckProject
    attribute(:sql_repository, kind_of: String, default: lazy { node['rundeck-sql']['repository'] }, required: true)
    attribute(:sql_revision, kind_of: String, default: lazy { node['rundeck-sql']['revision'] })
    attribute(:sql_globs, kind_of: Array, default: [], required: true)
    attribute(:sql_remote_directory, kind_of: String)     # For debugging, use remote_directory instead of git, set to the name of the cookbook

    def sql_target_destination
      ::File.join(project_path, 'sql')
    end

  end

  class Provider::RundeckSqlProject < Provider::RundeckProject
    include Chef::Mixin::ShellOut

    private

    def write_project_config
      create_node_source
      r = super
      # Run these first since we need it installed to parse jobs
      notifying_block do
        install_postgres
        clone_sql_repository
      end
      create_sql_jobs
      r
    end

    def create_node_source
      rundeck_sql_node_source new_resource.name do
        parent new_resource
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
        git new_resource.sql_target_destination do
          user 'root'
          group 'root'
          repository new_resource.sql_repository
          revision new_resource.sql_revision
          action :sync
        end
      end
    end

    def create_sql_jobs
      parse_sql_tasks.each_pair do |schedule, sql_files|

        sql_files.each do |sql_file|
          rundeck_job task['name'] do
            parent new_resource
            source "#{schedule}.yml.erb"
            options(
                :commands => [
                    "psql --dbname=#{task['name']} -f #{sql_file}"
                ]
            )
          end
        end
      end
    end

    def parse_sql_tasks
      tasks = {'monthly' => [], 'daily' => [], 'weekly' => []}
      Dir.chdir(new_resource.sql_target_destination) do |path|
        new_resource.sql_globs.each do |glob_string|
          files = Dir.glob(glob_string)
          next if files.nil?
          tasks.keys do |key|
            if files.first?.contains(keys)
              tasks[key] + files
            end
          end
        end
      end
      tasks
    end

  end
end
