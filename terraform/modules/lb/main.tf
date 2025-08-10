resource "random_string" "dns" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_public_ip" "lb" {
  name                = "${var.lb_name_prefix}-pip"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = lower(replace("${var.lb_name_prefix}-${random_string.dns.result}", "_", "-"))
  tags                = var.tags
}

resource "azurerm_lb" "this" {
  name                = var.lb_name_prefix
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "feip"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = var.tags
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  name            = "bepool"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "http" {
  name            = "http-probe"
  loadbalancer_id = azurerm_lb.this.id
  port            = var.probe_port
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "http" {
  name                           = "http-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = var.frontend_port
  backend_port                   = var.backend_port
  frontend_ip_configuration_name = "feip"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.bpepool.id]
  probe_id                       = azurerm_lb_probe.http.id
}

resource "azurerm_network_interface_backend_address_pool_association" "bep_assoc" {
  count                   = length(var.backend_pool_vms_nic_ids)
  network_interface_id    = var.backend_pool_vms_nic_ids[count.index]
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.bpepool.id
}

resource "azurerm_lb_nat_rule" "ssh" {
  count                          = length(var.backend_pool_vms_nic_ids)
  name                           = "ssh-${count.index + 1}"
  resource_group_name            = var.rg_name
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = 50000 + count.index
  backend_port                   = 22
  frontend_ip_configuration_name = "feip"
}

resource "azurerm_network_interface_nat_rule_association" "ssh_assoc" {
  count                 = length(var.backend_pool_vms_nic_ids)
  network_interface_id  = var.backend_pool_vms_nic_ids[count.index]
  ip_configuration_name = "ipconfig1"
  nat_rule_id           = azurerm_lb_nat_rule.ssh[count.index].id
}
