resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.application_name}-${var.environment_name}"
  location = var.region
}

resource "azurerm_network_interface" "nic_vm1" {
  name                = "nic_vm1${var.application_name}${var.environment_name}"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_vm1.id
  }

}

resource "azurerm_public_ip" "pip_vm1" {
  name                = "pip_vm1${var.application_name}${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = pathexpand("~/.ssh/vm1")
  file_permission = 0600

}

resource "local_file" "public_key" {
  content  = tls_private_key.ssh_key.public_key_openssh
  filename = pathexpand("~/.ssh/vm1.pub")
}

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "vm1${var.application_name}${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic_vm1.id,
  ]

  encryption_at_host_enabled = true

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    disk_encryption_set_id = azurerm_disk_encryption_set.disk_encryption_set.id
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

data "azurerm_client_config" "config" {

}

resource "azurerm_key_vault" "keyvault" {
  name                        = "kv-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  location                    = var.region
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.config.tenant_id
  sku_name                    = "standard"
  enable_rbac_authorization   = "true"
  enabled_for_disk_encryption = "true"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true

}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "key vault administrator"
  principal_id         = data.azurerm_client_config.user.object_id
}

resource "azurerm_role_assignment" "example-disk" {
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_disk_encryption_set.disk_encryption_set.identity[0].principal_id
}

resource "azurerm_key_vault_key" "key" {
  name         = "key-${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
  key_vault_id = azurerm_key_vault.keyvault.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "wrapKey", "unwrapKey", "verify"]

}
data "azurerm_subscription" "sub" {
}

data "azurerm_client_config" "user" {
}

resource "azurerm_disk_encryption_set" "disk_encryption_set" {
  name                = "des-${var.application_name}-${var.environment_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  key_vault_key_id    = azurerm_key_vault_key.key.id

  identity {
    type = "SystemAssigned"
  }
}
