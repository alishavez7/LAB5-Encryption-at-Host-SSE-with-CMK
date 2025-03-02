# create dev virtual network 
locals {
  app_subnet_address_space = cidrsubnet(var.base_address_space, 2, 0)
  db_subnet_address_space  = cidrsubnet(var.base_address_space, 2, 1)
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.application_name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.base_address_space]
  location            = var.region
}

resource "azurerm_subnet" "app_subnet" {
  name                 = "app-subnet-${var.application_name}-${var.environment_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.app_subnet_address_space]

}

resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet-${var.application_name}-${var.environment_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [local.db_subnet_address_space]

}
