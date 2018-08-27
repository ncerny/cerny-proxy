#
# Cookbook:: cerny-proxy
# Recipe:: default
#
# Copyright:: 2018, Nathan Cerny
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

include_recipe "cerny-loadbalancer::deps"
package 'glb-redirect'
kernel_module 'fou'

systemd_unit 'glb-redirect.service' do
  content <<-EOU.gsub(/^\s+/, '')
    [Unit]
    Description=Configure GUE and IPTables Rules for GLB proxy layer.
    After=network.target

    [Service]
    ExecStart=/bin/ip fou add port 19523 gue
    ExecStartPost=/sbin/iptables -t raw -A INPUT -p udp -m udp --dport 19523 -j CT --notrack
    ExecStartPost=/sbin/iptables -A INPUT -p udp -m udp --dport 19523 -j GLBREDIRECT
    ExecStop=/bin/ip fou del port 19523 gue
    RemainAfterExit=true

    [Install]
    WantedBy=multi-user.target
  EOU
end

service 'glb-redirect' do
  action [:enable, :start]
end

template '/etc/network/interfaces.d/tunl0.conf' do
  source 'tunl0.conf.erb'
  notifies :run, 'execute[ifup tunl0]', :immediately
end
