# Policyfile.rb - Describe how you want Chef to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

name 'cerny-proxy'

default_source :supermarket

run_list 'cerny-proxy::default'

cookbook 'cerny-proxy', path: '..'
cookbook 'cerny-loadbalancer', github: 'ncerny/cerny-loadbalancer', branch: 'master'
