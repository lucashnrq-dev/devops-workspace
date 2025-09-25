provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-automation"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-automation"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


resource "azurerm_network_interface" "nic" {
  name                = "nic-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Swagger"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8081"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "vm-automation"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  admin_password                  = var.admin_password
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKj7dG+zTViCiCBoAGMumop62gxXlySjG5fV4Dt6BDfC6LRPDxVnyaH45aFMVFKuEW5vmr/G47BGiVRwKn469OJOEUNIRnSDT8D4GKhGSAEWzUcHIUT72uGMTKptvzq6MyQ04WQBMKTBZHVttiSoG+Wk8yMJBPErloV32vNyem24JV3GexerEP9dFUBgEsncvyqOwLjpJpdKdCesuIvxD4uPzE8Rhi0K2ox0dBksJcZ5MhIx19dcNOacG1EZ78hckoRQxygi1pNAjLq/yg373arLs1Dz5xSnGuskAqhsfqAQndYmMxov9kvEDHgOPHFTYvJ2TDOSzz82F3xBMMVgG63UwO30DTdcmPrNHR1rorsPATyonAw56JbxkNWwMHRM8z63IJAEJgym9qOOJNX0AnzWJdLQBe9ZjHV+/7O4NRCfRR4vtrdjW6CyifyXNXfScwReZdxMTKWpVSwjJJYmMrsIOT46xUFiYjPzxthnM66tDS7j2gwomx7qLdJbR5CoIi8IjxuusnyhH/QzX0kKWjccdyM1Ea286iWbSkTZRy33sb2ytsPcI/fDzG6XJ8fNWhniA5O/vlSu8r3mox5OS1pmA06RnYE0F5LzukTMbJB+dGACkOhtd5iURWU0Jo3sXhkHE1Hjx6EaVHpF6q0lQPGCaE2cp9jFf8SCsXPQs5Fw== lucashsilvaa8@gmail.com
  }

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}
