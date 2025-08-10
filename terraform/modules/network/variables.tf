variable "rg_name"       { type = string }
variable "location"      { type = string }
variable "address_space" { type = list(string) }
variable "subnet_map"    { type = map(string) }  # vm, mgmt, db, bastion
variable "tags"          { type = map(string) }
