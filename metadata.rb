name 'cerny-proxy'
maintainer 'Nathan Cerny'
maintainer_email 'ncerny@gmail.com'
license 'Apache-2.0'
description 'Installs/Configures cerny-proxy'
long_description 'Installs/Configures cerny-proxy'
version '0.3.0'
chef_version '>= 12.14' if respond_to?(:chef_version)
issues_url 'https://github.com/ncerny/cerny-proxy/issues'
source_url 'https://github.com/ncerny/cerny-proxy'

supports 'debian', '>= 9'

depends 'cerny-loadbalancer'
depends 'packagecloud'
depends 'kernel_module'
depends 'docker'
