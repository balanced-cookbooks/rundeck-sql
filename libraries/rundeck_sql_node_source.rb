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
  class Resource::RundeckSqlNodeSource < Resource::RundeckNodeSourceFile
    def nodes
      [{
        'name' => 'localhost',
        'description' => 'Rundeck server',
        'roles' => [],
        'recipes' => [],
        'fqdn' => 'localhost',
        'os' => node['os'],
        'kernel_machine' => node['kernel']['machine'],
        'kernel_name' => node['kernel']['name'],
        'kernel_release' => node['kernel']['release'],
      }]
    end
  end

  class Provider::RundeckSqlNodeSource < Provider::RundeckNodeSourceFile
    # This space left intentionally blank
  end
end
