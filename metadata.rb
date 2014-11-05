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

name 'rundeck-sql'
version '1.0.14'

maintainer 'Mahmoud Abdelkader'
maintainer_email 'mahmoud@balancedpayments.com'
license 'Apache 2.0'
description 'Use SQL scripts and Rundeck for great good'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

depends 'git'
depends 'rundeck', '~> 99.1.0'
depends 'balanced-postgresql'
depends 'balanced-citadel'
depends 'postfix'
