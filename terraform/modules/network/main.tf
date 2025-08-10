resource "azurerm_virtual_network" "this" {
  name                = "vnet-${replace(var.rg_name, " ", "")}"
  location            = var.location
  resource_group_name = var.rg_name
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each             = var.subnet_map
  name                 = each.key == "bastion" ? "AzureBastionSubnet" : "${each.key}-subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

resource "azurerm_network_security_group" "this" {
  for_each            = { for k, v in var.subnet_map : k => v if k != "bastion" }
  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["vm"].name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = var.rg_name
  network_security_group_name = azurerm_network_security_group.this["vm"].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = azurerm_network_security_group.this
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value.id
}
