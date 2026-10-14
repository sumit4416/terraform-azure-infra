output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "load_balancer_public_ip" {
  description = "Browser me http://<ip> kholo"
  value       = module.loadbalancer.public_ip_address
}

output "vm_private_ips" {
  value = module.vm.private_ips
}

output "aks_cluster_name" {
  value = module.aks.cluster_name
}

output "aks_kube_config" {
  value     = module.aks.kube_config_raw
  sensitive = true
}
