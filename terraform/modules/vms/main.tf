resource "random_string" "rand" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_storage_account" "bootdiag" {
  name                     = "bd${random_string.rand.result}sa"
  resource_group_name      = var.rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "vm${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

resource "azurerm_availability_set" "avs" {
  name                         = "linux-avs"
  location                     = var.location
  resource_group_name          = var.rg_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  managed                      = true
  tags                         = var.tags
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  count               = var.vm_count
  name                = "linux-vm-${count.index + 1}"
  location            = var.location
  resource_group_name = var.rg_name
  size                = var.vm_size
  admin_username      = var.admin_username
  availability_set_id = azurerm_availability_set.avs.id

  network_interface_ids = [ azurerm_network_interface.nic[count.index].id ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.linux_image.publisher
    offer     = var.linux_image.offer
    sku       = var.linux_image.sku
    version   = var.linux_image.version
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.bootdiag.primary_blob_endpoint
  }

  tags = var.tags
}

resource "azurerm_managed_disk" "data" {
  count                = var.vm_count
  name                 = "vm${count.index + 1}-data1"
  location             = var.location
  resource_group_name  = var.rg_name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.vm_count
  managed_disk_id    = azurerm_managed_disk.data[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.linux_vm[count.index].id
  lun                = 1
  caching            = "ReadWrite"
}
