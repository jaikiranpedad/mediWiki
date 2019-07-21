provider "azurerm" {
    subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}

#Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "mediwikigroup" {
    name     = "mediwikigroup"
    tags = {
        environment = "mediwiki"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "mediwikinetwork" {
    name                = "mediwikiVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.mediwikigroup.name}"

    tags = {
        environment = "mediwiki"
    }
}

# create subnet
resource "azurerm_subnet" "mediwikisubnet" {
    name                 = "mediwikisubnet"
    resource_group_name  = "${azurerm_resource_group.mediwikigroup.name}"
    virtual_network_name = "${azurerm_virtual_network.mediwikinetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

#create network insterfaces
resource "azurerm_network_interface" "mediwikinic" {
  count = "${length(var.nodes)}"
  name                = "${lookup(var.nodes[count.index], "name")}"
  location            = "eastus"
  resource_group_name = "${azurerm_resource_group.mediwikigroup.name}"

  ip_configuration {
    name                          = "${lookup(var.nodes[count.index], "name")}"
    subnet_id                     = "${azurerm_subnet.mediwikisubnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
    tags = {
        environment = "mediwiki"
    }
}

#Create virtual machines
resource "azurerm_virtual_machine" "myterraformvm" {
    count = "${length(var.nodes)}"
    name                  = "${lookup(var.nodes[count.index], "name")}"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.mediwikigroup.name}"
    network_interface_ids = ["${azurerm_network_interface.mediwikinic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "WikiOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "RedHat"
        offer     = "RHEL"
        sku       = "7-RAW"
        version   = "latest"
    }

    os_profile {
        computer_name  = "mediawiki"
        admin_username = "admin"
        admin_password = "pa55w0rd"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    tags = {
        environment = "mediwiki"
    }
}

\
