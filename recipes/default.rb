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

include_recipe "cerny-loadbalancer::proxy"

docker_service 'default' do
  action [:create, :start]
end

%w(
  quay.io/coreos/dnsmasq
  ncerny/matchbox
  consul
  traefik
  nginxdemos/hello
).each do |image|
  docker_image image do
    action :pull
    tag 'latest'
  end
end

docker_image 'nginx' do
  action :pull
  tag 'stable-alpine'
end

docker_container 'traefik' do
  repo 'traefik'
  port [
    '80:80',
    '443:443',
    '8080:8080',
    '8006:8006',
    '32400:32400'
  ]
  volumes [
    '/var/run/docker.sock:/var/run/docker.sock'
  ]
  command '--api --docker'
end

docker_container 'hello' do
  repo 'nginxdemos/hello'
  labels 'traefik.frontend.rule=Host:whoami.delivered.cerny.cc'
end


# docker_container 'matchbox' do
#   repo 'ncerny/matchbox'
#   port ['9080:9080', '9081:9081', '9631:9631']
# end

# $ docker run -d --net=host -e 'CONSUL_LOCAL_CONFIG={"skip_leave_on_interrupt": true}' consul agent -server -bind=<external ip> -retry-join=<root agent ip> -bootstrap-expect=<number of server agents>
