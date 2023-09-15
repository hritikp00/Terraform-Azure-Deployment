# Configure the Azure provider  
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.45.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  features {}
}

# Resource Group (bvkrg)
resource "azurerm_resource_group" "bvkrg" {
  name     = "rg-bvk-01"
  location = "central India"

}

# Virtual Network (main)
resource "azurerm_virtual_network" "main" {
  name                = "vnet01"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.bvkrg.location
  resource_group_name = azurerm_resource_group.bvkrg.name
}

# Subnet (internal)
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.bvkrg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Interface Card
resource "azurerm_network_interface" "main" {
  name                = "nic"
  location            = azurerm_resource_group.bvkrg.location
  resource_group_name = azurerm_resource_group.bvkrg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine 
resource "azurerm_virtual_machine" "vm01" {
  name                  = "vm01"
  location              = azurerm_resource_group.bvkrg.location
  resource_group_name   = azurerm_resource_group.bvkrg.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  # Operating System 
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}