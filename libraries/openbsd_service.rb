# Based on Chef::Provider::Service::Freebsd and adapted to work with OpenBSD's
# rc.d system by:
#  Joe Miller (https://github.com/joemiller / https://twitter.com/miller_joe)

#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# License:: Apache License, Version 2.0
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

require 'chef/mixin/shell_out'
require 'chef/provider/service'
require 'chef/mixin/command'

class Chef
  class Provider
    class Service
      class Openbsd < Chef::Provider::Service::Init
        RC_CONF_LOCAL = '/etc/rc.conf.local'
        PKG_SCRIPTS_CONF = '/etc/pkg_scripts.conf'

        include Chef::Mixin::ShellOut

        def load_current_resource
          @current_resource = Chef::Resource::Service.new(@new_resource.name)
          @current_resource.service_name(@new_resource.service_name)

          @rcd_script_found = true
          @enabled_state_found = false

          # Determine if we're talking about /etc/rc.d or /usr/local/etc/rc.d or special service (eg. ipsec)
          if ::File.exists?("/etc/rc.d/#{current_resource.service_name}")
            @init_command = "/etc/rc.d/#{current_resource.service_name}"
          elsif ::File.exists?("/usr/local/etc/rc.d/#{current_resource.service_name}")
            @init_command = "/usr/local/etc/rc.d/#{current_resource.service_name}"
          else
            @rcd_script_found = false
            return unless is_special_service?
          end

          if is_special_service?
            @enabled_state_found = true
            Chef::Log.debug("#{@current_resource} is special service.")
          else
            determine_current_status!
            Chef::Log.debug("#{@current_resource} found at #{@init_command}")
          end

          begin
            determine_current_enabled_status!
          rescue
            @enabled_state_found = false
          end

          unless @enabled_state_found
            Chef::Log.debug("#{@new_resource.name} enable/disable state unknown")
            @current_resource.enabled false
          end

          install_pkg_scripts_hook

          @current_resource
        end

        def define_resource_requirements
          shared_resource_requirements

          # In special service, only :enable supported
          requirements.assert(:start, :reload, :restart) do |a|
            a.assertion { @rcd_script_found }
            a.failure_message Chef::Exceptions::Service, "#{@new_resource}: unable to locate the rc.d script"
          end

          requirements.assert(:enable) do |a|
            a.assertion { @rcd_script_found || is_special_service? }
            a.failure_message Chef::Exceptions::Service, "#{@new_resource}: unable to locate the rc.d script"
          end

          requirements.assert(:all_actions) do |a|
            a.assertion { @enabled_state_found }
            # for consistentcy with original behavior, this will not fail in non-whyrun mode;
            # rather it will silently set enabled state=>false
            a.whyrun "Unable to determine enabled/disabled state, assuming this will be correct for an actual run.  Assuming disabled." 
          end

          requirements.assert(:start, :reload, :restart) do |a|
            a.assertion { @rcd_script_found && service_enable_variable_name != nil }
            a.failure_message Chef::Exceptions::Service, "Could not find the service name in #{@init_command} and rcvar"
            # No recovery in whyrun mode - the init file is present but not correct.
          end

          requirements.assert(:enable) do |a|
            a.assertion { (@rcd_script_found || is_special_service?) && service_enable_variable_name != nil }
            a.failure_message Chef::Exceptions::Service, "Could not find the service name in #{@init_command} and rcvar"
            # No recovery in whyrun mode - the init file is present but not correct.
          end
        end

        def determine_current_status!
          if shell_out("#{@init_command} check").exitstatus == 0
            @current_resource.running true
          else
            @current_resource.running false
          end
          Chef::Log.debug("#{@new_resource} is running")
        end

        def start_service
          if @new_resource.start_command
            super
          else
            shell_out!("#{@init_command} start")
          end
        end

        def stop_service
          if @new_resource.stop_command
            super
          else
            shell_out!("#{@init_command} -f stop")
          end
        end

        def restart_service
          if @new_resource.restart_command
            super
          elsif @new_resource.supports[:restart]
            shell_out!("#{@init_command} restart")
          else
            stop_service
            sleep 1
            start_service
          end
        end

        def read_conf(path)
          ::File.open(path, 'r') { |file|
            file.readlines
          }.map { |l|
            l.chomp
          }
        end

        def write_conf(path, lines)
          ::File.open(path, 'w') do |file|
            lines.each { |line| file.puts(line) }
          end
        end

        def read_rc_conf
          read_conf(RC_CONF_LOCAL)
        end

        def read_pkg_scripts_conf
          read_conf(PKG_SCRIPTS_CONF)
        end

        def write_rc_conf(lines)
          write_conf(RC_CONF_LOCAL, lines)
        end

        def write_pkg_scripts_conf(lines)
          write_conf(PKG_SCRIPTS_CONF, lines)
        end

        # The variable name used in /etc/rc.conf.local for enabling this service
        def service_enable_variable_name
          # we need no `_flags' suffix such as 'ipsec=YES`
          if is_special_service?
            @new_resource.service_name
          else
            "#{@new_resource.service_name}_flags"
          end
        end

        def set_service_enable(value)
          lines = begin
                    read_rc_conf
                  rescue Errno::ENOENT
                    []
                  end
          # Remove line that set the old value
          lines.delete_if { |line| line =~ /#{Regexp.escape(service_enable_variable_name)}/ }
          # And append the line that sets the new value at the end
          lines << "#{service_enable_variable_name}=\"#{value}\""
          write_rc_conf(lines)
        end

        def add_to_pkg_scripts_conf
          lines = begin
                    read_pkg_scripts_conf
                  rescue Errno::ENOENT
                    []
                  end
          # And append the line if no service name found
          unless lines.any? { |line| line == @current_resource.service_name }
            lines << @current_resource.service_name
            write_pkg_scripts_conf(lines)
          end
        end

        def remove_from_pkg_scripts_conf
          lines = begin
                    read_pkg_scripts_conf
                  rescue Errno::ENOENT
                    []
                  end
          # And append the line if no service name found
          lines.delete_if { |line| line == @current_resource.service_name }
          write_rc_conf(lines)
        end

        def enable_service()
          unless @current_resource.enabled
            if @new_resource.parameters
              if @new_resource.parameters.include?(:flags)
                set_service_enable(@new_resource.parameters[:flags])
              end
              if @new_resource.parameters[:pkg_script]
                add_to_pkg_scripts_conf
              end
            else
              set_service_enable("")
            end
          end
          if is_special_service?
            set_service_enable("YES")
          end
        end

        def disable_service()
          if @current_resource.enabled
            set_service_enable("NO")
            remove_from_pkg_scripts_conf
          end
        end

        def is_special_service?
          %w{ipsec pf bt}.any? { |s| @new_resource.service_name == s }
        end

        def determine_current_enabled_status!
          read_rc_conf.each do |line|
            case line
            when /#{Regexp.escape(service_enable_variable_name)}="(.*)"/
              @enabled_state_found = true
              if $1 =~ /[Nn][Oo][Nn]?[Oo]?[Nn]?[Ee]?/
                @current_resource.enabled false
              else
                @current_resource.enabled true
              end
            end
          end
          if @new_resource.parameters and @new_resource.parameters.include?(:pkg_script) and !is_special_service?
            @current_resource.enabled = read_pkg_scripts_conf.any? do |line|
              line.chomp == @current_resource.service_name
            end
          end
        end

        private
        def install_pkg_scripts_hook
          oneliner = "[ -f #{PKG_SCRIPTS_CONF} ] && for _r in `cat #{PKG_SCRIPTS_CONF}`; do pkg_scripts=\"${pkg_scripts} ${_r}\"; done"
          lines = begin
                    read_rc_conf
                  rescue
                    []
                  end
          unless lines.any? { |l| l.start_with?(oneliner) }
            lines << oneliner
            Chef::Log.info("Install #{PKG_SCRIPTS_CONF} hook in #{RC_CONF_LOCAL}")
            write_rc_conf(lines)
          end
        end
      end
    end
  end
end

Chef::Platform.set :platform => :openbsd, :resource => :service, :provider => Chef::Provider::Service::Openbsd
