variable "rg_name"        { type = string }
variable "location"       { type = string }
variable "subnet_id"      { type = string }
variable "vm_count"       { type = number }
variable "vm_size"        { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" { type = string }
variable "linux_image" {
  type = object({ publisher = string, offer = string, sku = string, version = string })
}
variable "tags"           { type = map(string) }
