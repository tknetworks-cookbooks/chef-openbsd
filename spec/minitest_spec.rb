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

  it 'installs/removes git via packages' do
    expect(chef_run).to remove_package 'git'
  end

  it 'installs zsh with version via packages' do
    expect(chef_run).to install_package_at_version 'zsh', '4.3.17'
  end

  it 'removes wget with version via packages' do
    expect(chef_run).to remove_package 'wget'
  end

  it 'enable/start ntpd service' do
    expect(chef_run).to enable_service 'ntpd'
    expect(chef_run).to start_service 'ntpd'
  end

  it 'stop/disable sndiod service' do
    expect(chef_run).to disable_service 'sndiod'
    expect(chef_run).to stop_service 'sndiod'
  end

  it 'enable ipsec special service' do
    expect(chef_run).to enable_service 'ipsec'
  end
end
