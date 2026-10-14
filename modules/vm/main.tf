variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "vm_count" { type = number }
variable "vm_size" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" { type = string }
variable "ssh_allowed_cidr" { type = string }
variable "lb_backend_pool_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.prefix}-vm-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_allowed_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "this" {
  count               = var.vm_count
  name                = "${var.prefix}-vm${count.index + 1}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.vm_count
  network_interface_id      = azurerm_network_interface.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.this[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = var.lb_backend_pool_id
}

resource "azurerm_linux_virtual_machine" "this" {
  count                 = var.vm_count
  name                  = "${var.prefix}-vm${count.index + 1}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.this[count.index].id]
  tags                  = var.tags

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # Har VM apna hostname dikhayegi, taaki load balancing visible ho
  custom_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    echo "<h1>Hello from ${var.prefix}-vm${count.index + 1}</h1>" > /var/www/html/index.html
    systemctl enable --now nginx
  EOT
  )

  depends_on = [azurerm_network_interface_backend_address_pool_association.this]
}

output "private_ips" {
  value = azurerm_network_interface.this[*].private_ip_address
}
