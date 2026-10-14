locals {
  prefix = "${var.project}-${var.environment}"

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.tags
}

module "vnet" {
  source = "./modules/vnet"

  name                = "${local.prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  subnets             = var.subnets
  tags                = local.tags
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  name                = "${local.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

module "vm" {
  source = "./modules/vm"

  prefix              = local.prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.vnet.subnet_ids["vm"]
  vm_count            = var.vm_count
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  ssh_public_key      = file(pathexpand(var.ssh_public_key_path))
  ssh_allowed_cidr    = var.ssh_allowed_cidr
  lb_backend_pool_id  = module.loadbalancer.backend_pool_id
  tags                = local.tags
}

module "aks" {
  source = "./modules/aks"

  name                = "${local.prefix}-aks"
  dns_prefix          = local.prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.vnet.subnet_ids["aks"]
  node_count          = var.aks_node_count
  vm_size             = var.aks_vm_size
  tags                = local.tags
}
