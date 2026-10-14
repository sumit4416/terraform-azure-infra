# Terraform Azure Infrastructure Deployment

Terraform modules se Azure par end-to-end infrastructure provision hota hai: **Virtual Network, Virtual Machines, Load Balancer aur AKS**. Terraform state **Azure Blob Storage** me remote store hoti hai.

**Tech:** Terraform · Azure · AKS · HCL · Azure CLI

## Architecture

```
                    Internet
                        |
              [ Public IP + Standard LB ]
                        |  (port 80)
        +---------------+---------------+
        |         VNet 10.0.0.0/16      |
        |                               |
        |  subnet "vm"  10.0.1.0/24     |
        |    VM1 (nginx)   VM2 (nginx)  |
        |                               |
        |  subnet "aks" 10.0.2.0/23     |
        |    AKS cluster (2 nodes)      |
        +-------------------------------+

Terraform state --> Azure Blob Storage (container: tfstate)
```

## Folder structure

```
.
├── main.tf                 # Resource group + saare modules ko jodta hai
├── variables.tf            # Input variables
├── outputs.tf              # LB IP, VM IPs, AKS name, kubeconfig
├── providers.tf            # azurerm provider
├── backend.tf              # Remote state (Azure Blob)
├── terraform.tfvars.example
├── scripts/create-backend.sh   # State storage account banata hai
└── modules/
    ├── vnet/               # VNet + subnets
    ├── loadbalancer/       # Public IP, Standard LB, probe, rule
    ├── vm/                 # NSG, NICs, Ubuntu VMs (nginx)
    └── aks/                # AKS cluster (Azure CNI, system identity)
```

## Deploy kaise kare

**Prerequisites:** Terraform >= 1.5, Azure CLI, ek SSH key (`ssh-keygen -t rsa -b 4096`).

```bash
# 1. Login
az login
az account show --query id -o tsv      # subscription ID

# 2. Remote state storage banao (sirf ek baar) -> backend.hcl bhi ban jata hai
bash scripts/create-backend.sh

# 3. Variables set karo
cp terraform.tfvars.example terraform.tfvars
#   subscription_id aur ssh_allowed_cidr (apna IP/32) edit karo

# 4. Init, plan, apply
terraform init -backend-config=backend.hcl
terraform plan -out=tfplan
terraform apply tfplan
```

## Verify

```bash
terraform output load_balancer_public_ip     # browser me http://<ip> kholo, refresh karte raho:
                                             # VM1 / VM2 alternate dikhega

az aks get-credentials -g tfazure-dev-rg -n tfazure-dev-aks
kubectl get nodes
```

## Cleanup (cost bachane ke liye)

```bash
terraform destroy
```

AKS aur LB ka cost lagta hai, isliye demo ke baad destroy kar do.

## Notes

- `terraform.tfvars`, `backend.hcl` aur state files `.gitignore` me hain, inhe commit mat karo.
- `ssh_allowed_cidr` default VNet ke andar hai (SSH internet se band). Apna public IP `x.x.x.x/32` daalo agar SSH chahiye.
- VMs ke public IP nahi hain; internet access (nginx install) LB ke outbound rule se milta hai.
