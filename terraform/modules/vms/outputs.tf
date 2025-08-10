output "private_ip_addresses" {
  value = [for n in azurerm_network_interface.nic : n.ip_configuration[0].private_ip_address]
}

output "nic_ids" {
  value = [for n in azurerm_network_interface.nic : n.id]
}
