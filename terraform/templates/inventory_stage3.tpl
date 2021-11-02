[all:vars]
ansible_python_interpreter=/usr/bin/python3
on_openstack=true

[k8s_nodes:children]
masters
workers

[frontend:children]
gateways

[masters]
%{ for index, instance in masters ~}
${instance.name} ansible_host=${master_ports[index].all_fixed_ips[0]} local_ipv4_address=${master_ports[index].all_fixed_ips[0]} %{if dualstack_support }${try("local_ipv6_address=${master_ports[index].all_fixed_ips[1]}", "")}%{ endif }
%{ endfor }

[gateways]
%{ for index, instance in gateways ~}
${instance.name} ansible_host=${gateway_ports[index].all_fixed_ips[0]} local_ipv4_address=${gateway_ports[index].all_fixed_ips[0]} %{if dualstack_support }${try("local_ipv6_address=${gateway_ports[index].all_fixed_ips[1]}", "")}%{ endif }
%{ endfor }

[workers]
%{ for index, instance in workers ~}
${instance.name} ansible_host=${worker_ports[index].all_fixed_ips[0]} local_ipv4_address=${worker_ports[index].all_fixed_ips[0]} %{if dualstack_support }${try("local_ipv6_address=${worker_ports[index].all_fixed_ips[1]}", "")}%{ endif }
%{ endfor }
