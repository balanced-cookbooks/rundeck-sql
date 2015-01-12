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

override['rundeck']['admin_password'] = 'admin'
override['rundeck']['external_scheme'] = 'http'
override['rundeck']['external_hostname'] = 'localhost'
override['rundeck']['external_port'] = '4441'

override['postgresql']['pg_hba_defaults'] = false
override['postgresql']['pg_hba'] = [
    {type: 'local', db: 'all', user: 'all', method: 'trust'},
    {type: 'host', db: 'all', user: 'all', addr: '0.0.0.0/0', method: 'trust'},
]

override['rundeck-sql']['success_email'] = 'test+original@balancedpayments.com'
override['rundeck-sql']['report_email_map'] = {
    'A SQL File With Spaces.sql' => {
        'to' => ['test+mapped@balancedpayments.com'],
        'from' => 'test+from@balancedpayments.com',
        'subject' => "Hey dude, check this shit out!",
        'bcc' => ['notice+bcc1@balancedpayments.com', 'm+bcc2@balancedpayments.com'],
        'body' => "Automated report for #{DateTime.now.to_s.gsub(':', '-')}. See attached."
    }
}