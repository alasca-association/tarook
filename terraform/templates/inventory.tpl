[all:vars]
ansible_python_interpreter=/usr/bin/python3
on_openstack=True
ipv6_enabled=%{ if ipv6_enabled }True%{ else }False%{ endif }
ipv4_enabled=%{ if ipv4_enabled }True%{ else }False%{ endif }

[orchestrator]
localhost ansible_connection=local ansible_python_interpreter="{{ ansible_playbook_python }}"

[frontend:children]
gateways

[k8s_nodes:children]
masters
workers

[gateways]
%{ for index, instance in gateways ~}
${instance.name} ansible_host=${gateway_fips[index].address} local_ipv4_address=${gateway_ports[index].all_fixed_ips[0]} %{if ipv6_enabled }${try("local_ipv6_address=${gateway_ports[index].all_fixed_ips[1]}", "")}%{ endif }
%{ endfor }

[masters]
%{ for index, instance in masters ~}
${instance.name} ansible_host=${master_ports[index].all_fixed_ips[0]} local_ipv4_address=${master_ports[index].all_fixed_ips[0]} %{if ipv6_enabled }${try("local_ipv6_address=${master_ports[index].all_fixed_ips[1]}", "")}%{ endif }
%{ endfor }

[workers]
%{ for index, instance in workers ~}
${instance.name} ansible_host=${worker_ports[index].all_fixed_ips[0]} local_ipv4_address=${worker_ports[index].all_fixed_ips[0]} %{if ipv6_enabled }${try("local_ipv6_address=${worker_ports[index].all_fixed_ips[1]}", "")}%{ endif }
%{ endfor }
