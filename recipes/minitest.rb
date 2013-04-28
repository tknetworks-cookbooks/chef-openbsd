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
execute "install-git" do
  action :nothing
  command "pkg_add git"
end.run_action(:run)

package "git" do
  action :remove
end

package "zsh" do
  action :install
  version '4.3.17'
end

execute "install-wget" do
  action :nothing
  command "pkg_add wget"
end.run_action(:run)

package "wget" do
  action :remove
  version '1.13.4'
end

service "ntpd" do
  action [:enable, :start]
end

service "sndiod" do
  action [:disable, :stop]
end

service "isakmpd" do
  action [:enable, :start]
  parameters(:flags => '-K -v')
end

service "ipsec" do
  action :enable
end
