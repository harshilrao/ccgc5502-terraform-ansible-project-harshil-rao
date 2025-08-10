terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 3.110.0" }
    random  = { source = "hashicorp/random",  version = ">= 3.5.1" }
    local   = { source = "hashicorp/local",   version = ">= 2.5.1" }
    null    = { source = "hashicorp/null",    version = ">= 3.2.2" }
  }
}

provider "azurerm" {
  features {}
}
