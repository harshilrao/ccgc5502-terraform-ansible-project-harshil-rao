output "resource_group_name" { value = module.resource_group.name }
output "vnet_name"           { value = module.network.vnet_name }
output "subnets"             { value = module.network.subnet_ids }
output "vm_private_ips"      { value = module.vms.private_ip_addresses }
output "lb_public_ip"        { value = module.lb.lb_public_ip }
output "lb_fqdn"             { value = module.lb.lb_fqdn }
