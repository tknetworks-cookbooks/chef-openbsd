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
require 'minitest/spec'

describe_recipe 'chef-openbsd::minitest' do
  it "installs zsh via packages" do
    package("zsh").must_be_installed.with(:version, '4.3.17')
  end

  it "uninstalls git without version via packages" do
    package("git").wont_be_installed
  end

  it "uninstalls wget with version via packages" do
    package("wget").wont_be_installed
  end

  it "does not install foobar via packages" do
    package("foobar").wont_be_installed
  end

  it "enables ntpd service" do
    service("ntpd").must_be_enabled
  end

  it "starts ntpd service" do
    service("ntpd").must_be_running
  end

  it "disables sndiod service" do
    service("sndiod").wont_be_enabled
  end

  it "stops sndiod service" do
    service("sndiod").wont_be_running
  end
end
