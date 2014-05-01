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

require 'serverspec'
require 'yaml'
include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

ENV['RDECK_BASE'] = '/var/lib/rundeck'


describe 'interrogate jobs' do

  context 'balanced' do
    let(:cmd) {
      backend.run_command('rd-jobs -p balanced --verbose')
    }

    it 'should succeed' do
      cmd.exit_status.to_i.should eql(0)
    end

    context 'should have two jobs' do
      subject do
        YAML.load(cmd.stdout)
      end
      its(:length) { should eql(2) }
    end

  end

  context 'precog' do

    let(:cmd) {
      backend.run_command('rd-jobs -p precog --verbose')
    }

    it 'should succeed' do
      cmd.exit_status.to_i.should eql(0)
    end


    context 'should have two jobs' do
      subject do
        YAML.load(cmd.stdout)
      end
      its(:length) { should eql(2) }
    end

  end

end


describe file('/var/lib/rundeck/projects/balanced/etc/project.properties') do
  it { should be_a_file }
  its(:content) { should include('config.file=/var/lib/rundeck/projects/balanced/etc/resources.xml') }
end

describe file('/var/lib/rundeck/projects/balanced/etc/resources.xml') do
  it { should be_a_file }
  its(:content) { should include('name="localhost"') }
end

describe file('/var/lib/rundeck/projects/balanced/sql') do
  it { should be_directory }
end

describe file('/var/lib/rundeck/projects/precog/etc/project.properties') do
  it { should be_a_file }
  its(:content) { should include('config.file=/var/lib/rundeck/projects/precog/etc/resources.xml') }
end

describe file('/var/lib/rundeck/projects/precog/etc/resources.xml') do
  it { should be_a_file }
  its(:content) { should include('name="localhost"') }
end

describe file('/var/lib/rundeck/projects/precog/sql') do
  it { should be_directory }
end