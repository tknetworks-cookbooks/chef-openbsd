#
# Author:: Ken-ichi TANABE (<nabeken@tknetworks.org>)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'chefspec'

describe 'chef-openbsd::minitest' do
  let (:chef_run) {
    ChefSpec::ChefRunner.new do |node|
      node.automatic_attrs['platform'] = 'openbsd'
    end.converge('chef-openbsd::minitest')
  }

  it 'should install/remove git via packages' do
    expect(chef_run).to remove_package 'git'
  end

  it 'should install zsh with version via packages' do
    expect(chef_run).to install_package_at_version 'zsh', '4.3.17'
  end

  it 'should remove wget with version via packages' do
    expect(chef_run).to remove_package 'wget'
  end

  it 'should enable/start ntpd service' do
    expect(chef_run).to enable_service 'ntpd'
    expect(chef_run).to start_service 'ntpd'
  end

  it 'should enable/start isakmpd service with flags' do
    expect(chef_run).to enable_service 'isakmpd'
    expect(chef_run).to start_service 'isakmpd'
  end

  it 'should stop/disable sndiod service' do
    expect(chef_run).to disable_service 'sndiod'
    expect(chef_run).to stop_service 'sndiod'
  end

  it 'should enable ipsec special service' do
    expect(chef_run).to enable_service 'ipsec'
  end

  it 'should enable bird' do
    expect(chef_run).to enable_service 'bird'
  end

end
