variable "subscription_id" {
  description = "Azure subscription ID (az account show --query id -o tsv)"
  type        = string
}

variable "project" {
  description = "Project name, resource names ke prefix me use hota hai"
  type        = string
  default     = "tfazure"
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "vnet_address_space" {
  description = "VNet CIDR"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnet name => CIDR"
  type        = map(string)
  default = {
    vm  = "10.0.1.0/24"
    aks = "10.0.2.0/23"
  }
}

variable "vm_count" {
  description = "Load balancer ke peeche kitni VMs"
  type        = number
  default     = 2
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Public SSH key ka path"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_allowed_cidr" {
  description = "SSH kahan se allowed hai (apna IP/32 daalo)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_node_count" {
  type    = number
  default = 2
}

variable "aks_vm_size" {
  type    = string
  default = "Standard_B2s"
}
