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

```markdown
Azure-Lab-Builder/
├── README.md
├── packer/
│   ├── build.pkr.hcl
│   └── ansible-playbooks/
│       ├── app.yml
│       ├── data.yml
│       └── web.yml
├── scripts/
│   └── verify-architecture-selection.sh
├── terraform/
│   ├── hub/
│   │   ├── main.tf
│   │   ├── providers.tf
│   │   └── variables.tf
│   └── spoke/
│       ├── main.tf
│       ├── providers.tf
│       └── variables.tf