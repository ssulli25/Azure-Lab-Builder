# Azure-Lab-Builder

## Overview

**Azure-Lab-Builder** is a project for deploying, configuring, and managing a modular Azure lab environment. It leverages Terraform, Packer, Ansible, and automation scripts to enable rapid, repeatable, and secure provisioning of hub-and-spoke and stand-alone topologies. Two spoke architectures are supported — a classic **3-tier** model (web/app/data tiers on VMSS + PostgreSQL) and a **microservices** model (AKS + Azure SQL Database) — selectable per deployment via a single workflow input.

---

## Architecture

Azure-Lab-Builder supports two **topologies** — **hub-and-spoke** and **stand-alone** — and within each topology two **spoke architectures** (selected via the `architecture_type` workflow input):

| `architecture_type` | Compute | Data tier | Ingress | Terraform directory |
|---|---|---|---|---|
| `3tier` | VMSS (web + app, Nginx + .NET via Packer/Ansible) | 2× PostgreSQL VMs behind internal LB | Application Gateway | `terraform/spoke-3tier/` |
| `microservices` | Azure Kubernetes Service (private API, Workload Identity, Azure CNI Overlay) | Azure SQL Database (PaaS, Entra-only auth, Private Endpoint) | App Gateway Ingress Controller (AGIC) | `terraform/spoke-microservices/` |

The same `terraform/hub/` is reused by both architectures and both topologies. Selecting `microservices` provisions an AKS cluster, ACR (Premium with Private Endpoint), Key Vault, a User-Assigned Managed Identity, NAT Gateway (when no hub firewall is present), and Private DNS zones for the relevant `privatelink` namespaces — see `terraform/spoke-microservices/main.tf` for the full inventory.

### Hub-and-Spoke Architecture

- **Hub Network:**  
  Centralized networking resources, shared services, and security controls (such as firewalls, bastion hosts, or VPN gateways). The hub acts as the core for connectivity and policy enforcement.
- **Spoke Networks:**  
  Isolated environments for workloads, each with their own subnets and resources. Spokes connect to the hub for shared services and inter-spoke communication. The workload layout depends on the selected `architecture_type` (3-tier vs microservices — see table above).
- **Custom Images & Provisioning (3-tier only):**  
  Supports consistent configuration of compute resources using Packer and Ansible.
- **Automation Scripts:**  
  Shell scripts for architecture verification and deployment logic.

**Use Case:**  
Ideal for comprehensive testing that requires centralized management, shared services, and network segmentation between multiple workloads or teams.

---

### Stand-Alone Architecture

- **Virtual Network:**  
  A single, isolated virtual network with dedicated subnets sized for the selected `architecture_type`.
- **Workload layout:**  
  Either web/app/data tiers (3-tier) or AKS + Azure SQL + supporting services (microservices) — see the table above.
- **Custom Images & Provisioning (3-tier only):**  
  Packer + Ansible build the VMSS images.
- **Network Security Groups (NSGs):**  
  Enforce traffic rules and segmentation between subnets and control access to the environment.
- **Automation Scripts:**  
  Shell scripts to verify architecture selection, automate deployment steps, and enforce environment standards.

**Use Case:**  
Best for application testing, self-contained environments or when centralized shared services are not required.

---

## Repository Structure

```
Azure-Lab-Builder/
├── README.md
├── LICENSE                              # MIT License file
├── packer/
│   ├── build.pkr.hcl                    # Packer build configuration
│   └── ansible-playbooks/
│       ├── app.yml                      # .NET application server configuration
│       ├── data.yml                     # PostgreSQL database configuration
│       └── web.yml                      # Nginx web server configuration
├── scripts/
│   ├── check-job-status.sh              # CI/CD job validation script
│   ├── restart-vm-vmss-per-sub.ps1      # VM/VMSS restart utility across subscriptions
│   ├── sub-cost-estimation.ps1          # Azure subscription cost analysis
│   ├── sub-quota-usage.ps1              # Subscription quota monitoring and reporting
│   ├── ubuntu-linux-vm-vmss-update.ps1  # Ubuntu VM/VMSS update automation
│   ├── verify-architecture-selection.sh # Architecture (true/false) deployment gate
│   └── verify-architecture-type.sh      # Validates architecture_type input (3tier|microservices)
├── terraform/
│   ├── hub/
│   │   ├── main.tf                      # Hub infrastructure resources (shared)
│   │   ├── providers.tf                 # Azure provider configuration
│   │   └── variables.tf                 # Hub configuration variables
│   ├── spoke-3tier/
│   │   ├── main.tf                      # 3-tier spoke (VMSS + PostgreSQL)
│   │   ├── providers.tf                 # Azure provider configuration
│   │   └── variables.tf                 # 3-tier spoke configuration variables
│   └── spoke-microservices/
│       ├── main.tf                      # Microservices spoke (AKS + Azure SQL)
│       ├── providers.tf                 # Azure provider configuration
│       └── variables.tf                 # Microservices spoke configuration variables
└── .github/
    └── workflows/
        ├── github-pipelines-build.yml              # General build pipeline (validates both spokes)
        ├── github-pipelines-build-packer.yml       # Packer image build pipeline (3-tier only)
        ├── github-pipelines-config-aks.yml         # Placeholder for AKS in-cluster baseline config
        ├── github-pipelines-deploy-hub+spoke.yml   # Hub-and-spoke deployment (architecture_type-aware)
        ├── github-pipelines-deploy-stand+alone.yml # Stand-alone deployment (architecture_type-aware)
        └── github-pipelines-deploy-utility.yml     # Utility scripts execution pipeline
```

### Tfvars convention

Per-environment Terraform variables are stored in a secure Azure Storage container (`sls-terraform-state-<env>` for hub+spoke, `sls-terraform-state-sa-<env>` for stand-alone) and downloaded at deploy time. A single shared file per env covers both architectures:

| Use | Filename |
|---|---|
| Hub | `hub.auto.tfvars` |
| Spoke (per env, both architectures) | `<env>.auto.tfvars` |

Organize the file with comment headers so you can see at a glance which keys belong to which architecture:

```hcl
# === Shared ===
Region            = "eastus"
VnetAddressSpace  = ["10.20.0.0/16"]

# === 3-tier ===
WebSubnetPrefix   = ["10.20.0.0/24"]
AppSubnetPrefix   = ["10.20.1.0/24"]
DataSubnetPrefix  = ["10.20.2.0/24"]
# (plus any other 3-tier-specific keys)

# === Microservices ===
AksSystemSubnetPrefix       = ["10.20.0.0/24"]
AksUserSubnetPrefix         = ["10.20.1.0/24"]
AppGwSubnetPrefix           = ["10.20.2.0/24"]
PrivateEndpointSubnetPrefix = ["10.20.3.0/24"]
SqlAdminLogin               = "sqladmin"
AksKubernetesVersion        = "1.30.4"
AksSystemNodeVmSize         = "Standard_D2s_v5"
AksUserNodeVmSize           = "Standard_D4s_v5"
AksUserNodeMin              = 1
AksUserNodeMax              = 3
AksPodCidr                  = "100.64.0.0/16"     # MUST NOT overlap any peered network
AksServiceCidr              = "172.16.0.0/16"
AksDnsServiceIp             = "172.16.0.10"
AcrSku                      = "Premium"
SqlDatabaseSku              = "GP_S_Gen5_2"
```

> When you run a given architecture, Terraform will emit a harmless `Warning: Value for undeclared variable` for each key that belongs to the OTHER architecture. This is cosmetic — `auto.tfvars` undeclared-variable warnings do not fail the run.
>
> The two architectures cannot coexist in the same env (the spoke VNet name `<EnvName>-<Region>-vnet` would collide). Deploy them into separate envs, or destroy one before standing up the other.

### Terraform state keys

| Use | State key |
|---|---|
| Hub | `hub.tfstate` |
| 3-tier spoke (per env) | `<env>-3tier.tfstate` |
| Microservices spoke (per env) | `<env>-microservices.tfstate` |

> **Backend migration note:** earlier versions used `<env>.tfstate` (no architecture suffix) for the 3-tier spoke. Before your next 3-tier deploy, in each `sls-terraform-state-<env>` and `sls-terraform-state-sa-<env>` container either:
>
> - **Rename** the existing blob `<env>.tfstate` → `<env>-3tier.tfstate` (Azure blobs cannot be renamed in place — copy then delete):
>
>   ```bash
>   az storage blob copy start \
>     --source-container <container> --source-blob <env>.tfstate \
>     --destination-container <container> --destination-blob <env>-3tier.tfstate \
>     --account-name <storage-account> --auth-mode login
>   az storage blob delete \
>     --container-name <container> --name <env>.tfstate \
>     --account-name <storage-account> --auth-mode login
>   ```
>
> - **OR start fresh** if you have no live 3-tier resources to track — the next apply will create a new `<env>-3tier.tfstate`, and you can delete the orphan `<env>.tfstate`.

## Prerequisites

### Required Tools
- **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)** (>= 2.30.0)
- **[Terraform](https://www.terraform.io/downloads.html)** (>= 1.0.0)
- **[Packer](https://www.packer.io/downloads)** (>= 1.7.0) - For custom image builds
- **[Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)** (>= 4.0.0) - For server configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.