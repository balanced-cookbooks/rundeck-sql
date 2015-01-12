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

default['rundeck-sql']['repository'] = nil
default['rundeck-sql']['revision'] = 'master'
default['rundeck-sql']['failure_email'] = 'test+failure@example.com'
default['rundeck-sql']['failure_url'] = 'https://example.com/notify-me/failure'
default['rundeck-sql']['success_email'] = 'test+success@example.com'
default['rundeck-sql']['success_url'] = 'https://example.com/notify-me/success'


# filename glob, [to (list), bcc, cc]
default['rundeck-sql']['report_email_map'] = {}