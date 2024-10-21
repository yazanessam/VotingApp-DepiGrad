provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "minikube-rg"
  location = "West Europe"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "minikube-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "minikube-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "minikube-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "minikube-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Kubernetes"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "minikube-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "minikube-ipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Network Interface Security Group Association
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual Machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "minikube-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS2_v2"

  storage_os_disk {
    name              = "minikube-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "minikube-vm"
    admin_username = var.admin_username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/adminuser/.ssh/authorized_keys"
      key_data = var.vm_ssh_key
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = var.private_vm_ssh_key
      host        = azurerm_public_ip.public_ip.ip_address
    }
    inline = [
      # Update the system packages
      "sudo apt-get update -y && sudo apt-get install -y conntrack socat golang apt-transport-https ca-certificates curl software-properties-common",

      # Add Docker’s official GPG key and repository
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
      "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",

      # Install Docker
      "sudo apt-get update -y && sudo apt-get install -y docker-ce docker-ce-cli containerd.io",

      # Install crictl
      "curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.24.0/crictl-v1.24.0-linux-amd64.tar.gz",
      "sudo tar zxvf crictl-v1.24.0-linux-amd64.tar.gz -C /usr/local/bin",
      "rm -f crictl-v1.24.0-linux-amd64.tar.gz",

      # Add current user to docker group to run without sudo
      "sudo usermod -aG docker ${var.admin_username}",

      # Install cri-dockerd
      "wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.15/cri-dockerd-0.3.15.amd64.tgz",
      "tar -xvf cri-dockerd-0.3.15.amd64.tgz",
      "sudo mv cri-dockerd/cri-dockerd /usr/local/bin/",
      "sudo chmod +x /usr/local/bin/cri-dockerd",

      # Create systemd service file for cri-dockerd
      "echo '[Unit]\nDescription=CRI for Docker\nAfter=network.target\n\n[Service]\nExecStart=/usr/local/bin/cri-dockerd\n\n[Install]\nWantedBy=multi-user.target' | sudo tee /etc/systemd/system/cri-dockerd.service",

      # Enable and start cri-dockerd
      "sudo systemctl enable cri-dockerd.service",
      "sudo systemctl start cri-dockerd.service",

      # Install Kubernetes (kubectl)
      "curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl",
      "chmod +x ./kubectl",
      "sudo mv ./kubectl /usr/local/bin/kubectl",

      # Install Minikube
      "curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64",
      "chmod +x minikube",
      "sudo install minikube /usr/local/bin/",

      # Install CNI plugins
      "sudo mkdir -p /opt/cni/bin",
      "sudo mkdir -p /etc/cni/net.d",
      "wget https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz",
      "sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v0.9.1.tgz",

      # Start Minikube
      "sudo minikube start --driver=none",

      # Check Minikube Status
      "sudo minikube status"
    ]
  }


  tags = {
    project = "minikube-voting-app"
    owner   = "Yazan"
  }
}
