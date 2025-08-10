variable "humber_id" {
  type = string
}

variable "location" {
  type    = string
  default = "Canada Central"
}

variable "rg_name" {
  type = string
}

variable "address_space" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "subnet_map" {
  description = "name => cidr"
  type        = map(string)
  default = {
    mgmt    = "10.10.1.0/24"
    vm      = "10.10.2.0/24"
    db      = "10.10.3.0/24"
    bastion = "10.10.100.0/27"
  }
}

variable "vm_count" {
  type    = number
  default = 3
}

variable "vm_size" {
  type    = string
  default = "Standard_B1ms"
}

variable "admin_username" {
  type = string
}

variable "ssh_public_key" {
  type = string
}

variable "linux_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

variable "common_tags" {
  type = map(string)
  default = {
    Project        = "CCGC 5502 Automation Project"
    Name           = "harshil.rao"
    ExpirationDate = "2024-12-31"
    Environment    = "Project"
  }
}
