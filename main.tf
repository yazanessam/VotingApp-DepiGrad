provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "k8s_rg" {
  name     = "k8s-resource-group"
  location = "East US" # Change as needed
}

# Virtual Network

resource "azurerm_virtual_network" "k8s_vnet" {
  name                = "k8s-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.k8s_rg.location
  resource_group_name = azurerm_resource_group.k8s_rg.name
}

# Subnet
resource "azurerm_subnet" "k8s_subnet" {
  name                 = "k8s-subnet"
  resource_group_name  = azurerm_resource_group.k8s_rg.name
  virtual_network_name = azurerm_virtual_network.k8s_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Master VM
resource "azurerm_linux_virtual_machine" "master_vm" {
  name                = "k8s-master"
  resource_group_name = azurerm_resource_group.k8s_rg.name
  location            = azurerm_resource_group.k8s_rg.location
  size                = "Standard_DS1_v2" # Adjust as needed
  admin_username      = "adminuser" # Your admin username
  admin_password      = "Password1234!" # Set a strong password

  network_interface_ids = [
    azurerm_network_interface.master_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type =  "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }

  # Specify the Ansible playbook to run during provisioning
  provision_vm_agent = true
  custom_data = base64encode(templatefile("path/to/ansible-k8s-master.sh", {
    admin_password = "Password1234!" # Pass variables as needed
  }))
}

resource "azurerm_network_interface" "master_nic" {
  name                = "k8s-master-nic"
  location            = azurerm_resource_group.k8s_rg.location
  resource_group_name = azurerm_resource_group.k8s_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8s_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Worker VMs
resource "azurerm_linux_virtual_machine" "worker_vm" {
  count               = 2 # Change this for more workers
  name                = "k8s-worker-${count.index + 1}"
  resource_group_name = azurerm_resource_group.k8s_rg.name
  location            = azurerm_resource_group.k8s_rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "Password1234!"

  network_interface_ids = [
    azurerm_network_interface.worker_nic[count.index].id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type =  "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }

  # Specify the Ansible playbook to run during provisioning
  provision_vm_agent = true
  custom_data = base64encode(templatefile("path/to/ansible-k8s-worker.sh", {
    master_ip = azurerm_linux_virtual_machine.master_vm.private_ip_address # Pass master IP to the script
  }))
}

resource "azurerm_network_interface" "worker_nic" {
  count               = 2
  name                = "k8s-worker-nic-${count.index + 1}"
  location            = azurerm_resource_group.k8s_rg.location
  resource_group_name = azurerm_resource_group.k8s_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.k8s_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
