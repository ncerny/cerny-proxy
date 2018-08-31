# Policyfile.rb - Describe how you want Chef to build your system.
#
# For more information on the Policyfile feature, visit
# https://docs.chef.io/policyfile.html

name 'cerny-proxy'
run_list 'cerny-proxy::default'

default_source :supermarket
cookbook 'cerny-proxy', path: '..'
