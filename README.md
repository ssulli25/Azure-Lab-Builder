# Azure-Lab-Builder

## Overview

**Azure-Lab-Builder** is a project for deploying, configuring, and managing a modular Azure lab environment. It leverages Terraform, Packer, Ansible, and automation scripts to enable rapid, repeatable, and secure provisioning of hub-and-spoke and stand-alone three-tier architectures. It utilizes network topologies, compute engines, and supporting resources for development, testing, or training scenarios.

---

## Architecture

Azure-Lab-Builder supports two primary deployment models: **hub-and-spoke** and **stand-alone three-tier** architectures. Both models are designed for modular, scalable, and secure Azure lab environments.

### Hub-and-Spoke Architecture

- **Hub Network:**  
  Centralized networking resources, shared services, and security controls (such as firewalls, bastion hosts, or VPN gateways). The hub acts as the core for connectivity and policy enforcement.
- **Spoke Networks:**  
  Isolated environments for workloads (web, app, data), each with their own subnets and resources. Spokes connect to the hub for shared services and inter-spoke communication.
- **Custom Images & Provisioning:**  
  Supports consistent configuration of compute resources using Packer, Ansible, or other provisioning tools.
- **Automation Scripts:**  
  Shell scripts for architecture verification and deployment logic.

**Use Case:**  
Ideal for comprehensive testing that requires centralized management, shared services, and network segmentation between multiple workloads or teams.

---

### Stand-Alone Three-Tier Architecture

- **Virtual Network:**  
  A single, isolated virtual network with dedicated subnets for each tier (web, app, data).
- **Workload Tiers:**  
  Web, application, and data tiers that can be configured to host relevant services for your solution.
- **Custom Images & Provisioning:**  
  Supports consistent configuration of compute resources using Packer, Ansible, or other provisioning tools.
- **Network Security Groups (NSGs):**  
  Enforce traffic rules and segmentation between tiers and control access to the environment.
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
│   └── verify-architecture-selection.sh # Architecture deployment validation
├── terraform/
│   ├── hub/
│   │   ├── main.tf                      # Hub infrastructure resources
│   │   ├── providers.tf                 # Azure provider configuration
│   │   └── variables.tf                 # Hub configuration variables
│   └── spoke/
│       ├── main.tf                      # Spoke infrastructure resources
│       ├── providers.tf                 # Azure provider configuration
│       └── variables.tf                 # Spoke configuration variables
└── .github/
    └── workflows/
        ├── github-pipelines-build.yml              # General build pipeline
        ├── github-pipelines-build-packer.yml       # Packer image build pipeline
        ├── github-pipelines-deploy-hub+spoke.yml   # Hub-and-spoke deployment
        ├── github-pipelines-deploy-stand+alone.yml # Stand-alone deployment
        └── github-pipelines-deploy-utility.yml     # Utility scripts execution pipeline
```

## Prerequisites

### Required Tools
- **[Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)** (>= 2.30.0)
- **[Terraform](https://www.terraform.io/downloads.html)** (>= 1.0.0)
- **[Packer](https://www.packer.io/downloads)** (>= 1.7.0) - For custom image builds
- **[Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)** (>= 4.0.0) - For server configuration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.