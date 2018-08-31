if node['domain'].eql?('infra.cerny.cc')
  default['consul']['config'] = 'CONSUL_LOCAL_CONFIG={"skip_leave_on_interrupt": true}'
else
  default['consul']['config'] = 'CONSUL_LOCAL_CONFIG={"skip_leave_on_interrupt": true, "retry_join_wan": ["pve01.infra.cerny.cc", "pve02.infra.cerny.cc", "pve03.infra.cerny.cc"]}'
end
