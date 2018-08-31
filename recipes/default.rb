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

habitat_channel = case node['domain']
when 'acceptance.cerny.cc'
  'unstable'
when 'integration.cerny.cc'
  'stable'
else
  node['domain'].split('.').first
end

docker_service 'default' do
  action [:create, :start]
end

%w(
  quay.io/coreos/dnsmasq
  ncerny/matchbox
).each do |image|
  docker_image image do
    action :pull
    tag 'latest'
    not_if { node['kernel']['release'].end_with?('pve') }
  end
end

%w(
  consul
  traefik
).each do |image|
  docker_image image do
    action :pull
    tag 'latest'
  end
end

docker_volume 'consul' do
  action :create
end

docker_container 'consul' do
  memory '512m'
  restart_policy 'unless-stopped'
  network_mode 'host'
  env node['consul']['config']
  command <<-EOC
    agent -server \
      -bind=#{node['ipaddress']} \
      -retry-join=proxy01 \
      -retry-join=proxy02 \
      -retry-join=proxy03 \
      -bootstrap-expect=3 \
      -datacenter=#{node['domain'].split('.').first} \
      -ui
  EOC
  volumes [
    'consul:/consul/data'
  ]
end

directory '/etc/traefik'
directory '/etc/traefik/config.d'

template '/etc/traefik/traefik.toml' do
  source 'traefik.toml.erb'
  notifies :run, 'docker_exec[upload traefik configuration to kv store]'
  notifies :restart, 'docker_container[traefik]'
end

docker_container 'traefik' do
  memory '2048m'
  restart_policy 'unless-stopped'
  repo 'traefik'
  network_mode 'host'
  env [
    "DO_AUTH_TOKEN=#{::File.read('/root/.traefik/digitalocean.key').strip}"
  ]
  volumes [
    '/var/run/docker.sock:/var/run/docker.sock',
    '/etc/traefik:/etc/traefik'
  ]
  command '--api --docker --consul'
end

docker_exec 'upload traefik configuration to kv store' do
  action :nothing
  container 'traefik'
  command %w( /traefik storeconfig --consul )
end

docker_container 'matchbox' do
  memory '256m'
  restart_policy 'unless-stopped'
  repo 'ncerny/matchbox'
  command "--channel #{habitat_channel} --strategy at-once"
  labels [
    "traefik.frontend.entryPoints:http",
    "traefik.frontend.rule:Host:matchbox.#{node['domain']},matchbox"
    ]
  not_if { node['kernel']['release'].end_with?('pve') }
end

docker_container 'dnsmasq' do
  memory '256m'
  restart_policy 'unless-stopped'
  repo 'quay.io/coreos/dnsmasq'
  network_mode 'host'
  cap_add %w(NET_ADMIN)
  command <<-EOF
    -d -q \
    --no-poll \
    --no-resolv \
    --no-poll \
    --no-hosts \
    --local-service \
    --dhcp-range=#{node['network']['default_gateway']},proxy,255.255.255.0 \
    --enable-tftp --tftp-root=/var/lib/tftpboot \
    --dhcp-userclass=set:ipxe,iPXE \
    --pxe-service=tag:#ipxe,x86PC,"PXE chainload to iPXE",undionly.kpxe \
    --pxe-service=tag:ipxe,x86PC,"iPXE",http://matchbox/boot.ipxe \
    --log-queries \
    --log-dhcp \
    --cache-size=1000 \
    --server=/consul/127.0.0.1#8600 \
    --server=#{node['network']['default_gateway']}
  EOF
  not_if { node['kernel']['release'].end_with?('pve') }
end
