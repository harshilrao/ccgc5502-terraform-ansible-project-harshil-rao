variable "rg_name"        { type = string }
variable "location"       { type = string }
variable "lb_name_prefix" { type = string }
variable "backend_pool_vms_nic_ids" { type = list(string) }
variable "frontend_port"  { type = number }
variable "backend_port"   { type = number }
variable "probe_port"     { type = number }
variable "tags"           { type = map(string) }
