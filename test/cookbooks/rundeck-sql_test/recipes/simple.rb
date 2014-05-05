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

include_recipe 'postgresql::server'

%w(balanced precog).each do |user|
  pg_user user do
    privileges superuser: true, createdb: true, login: true
    password nil
  end

  pg_database user do
    owner user
  end
end

rundeck_sql_project 'balanced-sql' do
  sql_repository 'balanced'
  sql_remote_directory 'rundeck-sql_test'
  sql_connection ({'username' => 'balanced', 'database' => 'balanced'})
  sql_globs ['monthly/*', 'daily/*']
end

rundeck_sql_project 'precog-sql' do
  sql_repository 'balanced'
  sql_remote_directory 'rundeck-sql_test'
  sql_connection ({'username' => 'precog', 'database' => 'precog'})
  sql_globs ['monthly/*', 'daily/*']
end
