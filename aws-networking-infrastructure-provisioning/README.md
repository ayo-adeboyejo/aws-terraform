# AWS Networking Infrastructure with Terraform

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

AWS networking infrastructure provisioned with Terraform, implementing a fully isolated VPC environment with public subnets, internet gateway, route tables, security groups, and multiple EC2 instances — all following Infrastructure as Code best practices.


---

## Table of Contents

- [AWS Networking Infrastructure with Terraform](#aws-networking-infrastructure-with-terraform)
  - [Table of Contents](#table-of-contents)
  - [Learning Objectives](#learning-objectives)
  - [Project Overview](#project-overview)
  - [Architecture](#architecture)
  - [Technologies Used](#technologies-used)
  - [Features](#features)
  - [Project Structure](#project-structure)
  - [Prerequisites](#prerequisites)
  - [Deployment Results](#deployment-results)
  - [Deployment](#deployment)
    - [Part 1 — Configure Variables](#part-1--configure-variables)
    - [Part 2 — Provision Infrastructure](#part-2--provision-infrastructure)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [State Management](#state-management)
  - [Learnings \& Challenges](#learnings--challenges)
    - [`for_each` over `count` for EC2 instances](#for_each-over-count-for-ec2-instances)
    - [Separating security group rules from the security group resource](#separating-security-group-rules-from-the-security-group-resource)
    - [`locals` vs `variables` for naming](#locals-vs-variables-for-naming)
    - [`formatdate` and `timestamp()` in common tags](#formatdate-and-timestamp-in-common-tags)
    - [State bucket must exist before `terraform init`](#state-bucket-must-exist-before-terraform-init)
  - [References](#references)
  - [Contact](#contact)

---

## Learning Objectives

This Terraform project was built to demonstrate practical, hands-on experience in the following areas:

- Designing and provisioning a **custom VPC** with public subnets, routing, and internet access
- Managing **multiple EC2 instances** from a single resource block using `for_each`
- Implementing a **consistent naming and tagging strategy** using `locals` and `merge()`
- Configuring **security groups** using the modern separate ingress/egress rule resources
- Storing **Terraform state remotely** in S3 with encryption and state locking
- Writing **reusable, validated variables** to safely control infrastructure configuration


---

## Project Overview

A complete AWS network stack is provisioned from scratch using Terraform — VPC, subnet, internet gateway, route table, security group, and a configurable number of EC2 instances. All resources share a consistent naming convention derived from the project name and environment, and all state is stored remotely in S3 with locking enabled to prevent concurrent modifications.

This infrastructure acts as a reusable foundation. Any workload requiring isolated, internet-accessible compute on AWS — web servers, API backends, build agents, or bastion hosts — can be deployed on top of it by simply adding server names to the `server_name` variable. No Terraform code needs to change.

The project was built to practise the discipline of treating infrastructure the same way application developers treat code: version-controlled, peer-reviewable, and reproducible across environments without manual steps.

---

## Architecture

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Public Route Table (0.0.0.0/0 → IGW)
    │
    ▼
VPC (10.0.0.0/16)
    │
    ▼
Public Subnet (10.0.1.0/24)
    │
    ▼
Security Group (admin_sg)
    │   ├── Inbound:  TCP port 22 (SSH) — 0.0.0.0/0
    │   └── Outbound: All traffic     — 0.0.0.0/0
    │
    ├── EC2 Instance [web]     ──► t4g.micro | Public IP | Detailed Monitoring
    ├── EC2 Instance [api]     ──► t4g.micro | Public IP | Detailed Monitoring
    └── EC2 Instance [worker]  ──► t4g.micro | Public IP | Detailed Monitoring
```

All EC2 instances live inside the same public subnet and share the same security group. The number and names of instances are controlled entirely by the `server_name` variable — no code changes are required to add or remove servers.

---

## Technologies Used

| Technology | Role |
|------------|------|
| Terraform >= 1.0 | Infrastructure provisioning and state management |
| AWS VPC | Isolated network environment |
| AWS EC2 | Compute instances (t4g.micro, ARM64) |
| AWS S3 | Remote Terraform state storage with encryption and locking |
| AWS Security Groups | Inbound/outbound traffic control |
| HashiCorp Random | Generating unique S3 bucket suffixes |
| HashiCorp Local | Reading user data scripts from disk |

---

## Features

| Feature | Detail |
|---------|--------|
| **Custom VPC** | Fully isolated network with configurable CIDR block |
| **Public subnet** | Internet-routable subnet with route table association |
| **Dynamic EC2 provisioning** | Any number of named instances via `for_each` on a `set(string)` |
| **Consistent naming** | All resources named using `${project_name}-${environment}-<resource>` |
| **Unified tagging** | `merge()` applies common tags + resource-specific Name tag on every resource |
| **Validated variables** | CIDR blocks validated with `cidrhost()`, environment restricted to `dev`/`staging`/`production` |
| **Remote state** | S3 backend with AES-256 encryption and native S3 state locking |
| **User data support** | EC2 bootstrap scripts loaded from local file via `data "local_file"` |

---

## Project Structure

```
aws-networking-infrastructure/
│
├── main.tf              # VPC, subnet, IGW, route table, security group, EC2
├── variables.tf         # All input variable declarations with validation
├── locals.tf            # Naming convention and common tags
├── outputs.tf           # VPC ID, EC2 IDs, public IPs, private IPs
├── providers.tf         # AWS, Random, Local provider configuration
├── backend.tf           # S3 remote state configuration
├── terraform.tfvars     # Variable values (not committed to version control)
└── scripts/
    └── user_data.sh     # EC2 bootstrap script
```

---

## Prerequisites

Before deploying, ensure the following are in place:

- [Terraform >= 1.0](https://developer.hashicorp.com/terraform/install) installed locally
- AWS CLI installed and configured (`aws configure`) with sufficient IAM permissions to create VPC, EC2, S3, and security group resources
- **An existing S3 bucket** for storing remote Terraform state — create one manually in the AWS console or CLI before running `terraform init`
- **An existing EC2 key pair** in your target AWS region — create one in the AWS console under EC2 → Key Pairs and reference it via the `key_name` argument in the EC2 resource

> If the S3 state bucket or EC2 key pair do not exist before running `terraform init`, initialisation will fail. These two resources must be created manually as a one-time setup step.

---

## Deployment Results

<figure>
  <img src="./project-screenshots/security group.JPG " alt="Security Page">
  <figcaption>Admin Security Group</figcaption>
</figure>


---

<figure>
  <img src="./project-screenshots/remote state file.JPG " alt="Security Page">
  <figcaption>Terraform Remote State</figcaption>
</figure>

---
<figure>
  <img src="./project-screenshots/instances created.JPG " alt="Security Page">
  <figcaption>Terraform Remote State</figcaption>
</figure>

---


figure>
  <img src="./project-screenshots/tf apply output.JPG " alt="Security Page">
  <figcaption>Terraform Apply Output</figcaption>
</figure>

---


## Deployment

> ⚠️ **Cost Notice:** Resources provisioned by this project will incur AWS charges. Always run `terraform destroy` when the infrastructure is no longer needed to avoid unexpected costs.

### Part 1 — Configure Variables

**1. Create your S3 state bucket** (one-time, if it doesn't exist):

```bash
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning on the state bucket
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled
```

**2. Create a `terraform.tfvars` file** in the project root:

```hcl
project_name       = "myproject"
environment        = "dev"
region             = "ap-south-1"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
enable_monitoring  = true
enable_public_ip   = true

server_name = ["web", "api", "worker"]

tags = {
  Owner = "your-name"
  Team  = "devops"
}
```

> `terraform.tfvars` is listed in `.gitignore` and should never be committed to version control.

**3. Update the S3 backend** in your backend configuration to match your state bucket:

```hcl
terraform {
  backend "s3" {
    bucket       = "your-terraform-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

---

### Part 2 — Provision Infrastructure

```bash
# Initialise Terraform and download providers
terraform init

# Preview what will be created
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted. Terraform will provision all resources in the correct dependency order — VPC first, then subnet, then IGW, then route table, then security group, then EC2 instances.

**Verify the deployment:**

```bash
# List all resources in state
terraform state list

# Show outputs
terraform output
```

Expected outputs:

```
ec2_ids = {
  "api"    = "i-0abc123..."
  "web"    = "i-0def456..."
  "worker" = "i-0ghi789..."
}

ec2_public_ips = {
  "api"    = "13.x.x.x"
  "web"    = "15.x.x.x"
  "worker" = "65.x.x.x"
}

vpc_id = "vpc-0abc123..."
```

**SSH into an instance:**

```bash
ssh -i your-key.pem ubuntu@<public-ip>
```

**Tear down all resources when done:**

```bash
terraform destroy
```

> ⚠️ Running `terraform destroy` will permanently delete all provisioned resources. Confirm you no longer need the infrastructure before running this command.

---

## Inputs

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | `string` | — | Name of the project (used in all resource names) |
| `environment` | `string` | `staging` | Environment: `dev`, `staging`, or `production` |
| `region` | `string` | — | AWS region for all resources |
| `vpc_cidr` | `string` | `10.0.0.0/16` | CIDR block for the VPC |
| `public_subnet_cidr` | `string` | `10.0.1.0/24` | CIDR block for the public subnet |
| `availability_zone` | `list(string)` | `["ap-south-1", "ap-south-2"]` | Available AZs |
| `enable_monitoring` | `bool` | `true` | Enable detailed EC2 monitoring |
| `enable_public_ip` | `bool` | `true` | Assign public IPs to EC2 instances |
| `server_name` | `set(string)` | — | Set of server names to provision as EC2 instances |
| `tags` | `map(string)` | `{}` | Additional tags to apply to all resources |

---

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `ec2_ids` | Map of server name → EC2 instance ID |
| `ec2_public_ips` | Map of server name → public IP address |
| `ec2_private_ip` | Map of server name → private IP address |

---

## State Management

Terraform state is stored remotely in S3 with the following configuration:

| Setting | Value |
|---------|-------|
| Backend | S3 |
| Encryption | AES-256 (server-side) |
| State locking | Native S3 locking (`use_lockfile = true`) |
| State path | `dev/terraform.tfstate` |

State locking prevents two engineers from running `terraform apply` simultaneously and corrupting the state file. This is especially important in team environments. The S3 bucket itself should have versioning enabled so previous state versions can be recovered if the state file is accidentally corrupted or deleted.

---

## Learnings & Challenges

### `for_each` over `count` for EC2 instances
An early design decision was whether to use `count` or `for_each` to provision multiple EC2 instances. `count` was simpler but identifies instances by numeric index — removing one instance from the middle causes Terraform to renumber all subsequent instances, triggering unnecessary destroys and recreates. `for_each` with a `set(string)` uses the server name as the key, meaning each instance is independently addressable. Removing `"worker"` only destroys the worker instance — `"web"` and `"api"` are untouched.

### Separating security group rules from the security group resource
AWS introduced `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` as standalone resources, separate from the `aws_security_group` block. This is the modern approach and avoids a known conflict where inline `ingress`/`egress` blocks and separate rule resources fight over the same state, causing rules to be unexpectedly removed on apply. Keeping the security group declaration clean and rules as independent resources also makes it easier to add or remove individual rules without touching the group itself.

### `locals` vs `variables` for naming
All resource names are derived in `locals` rather than exposed as variables, because names should be computed consistently from `project_name` and `environment` — not set independently per resource. Exposing names as variables would allow them to drift out of convention. `locals` enforces the naming pattern centrally: change `project_name` once and every resource name updates automatically.

### `formatdate` and `timestamp()` in common tags
Adding `CreatedDate = formatdate("YYYY-MM-DD", timestamp())` to common tags records when resources were provisioned. One important behaviour to note: `timestamp()` is evaluated at plan time, so running `terraform apply` again will show a diff on the tag even if nothing else changed. For immutable creation timestamps, consider adding `ignore_changes = [tags["CreatedDate"]]` inside the resource `lifecycle` block to suppress this on subsequent applies.

### State bucket must exist before `terraform init`
A subtle bootstrapping issue: the S3 backend block is read before any Terraform resources are created, meaning the state bucket itself cannot be managed by the same Terraform config that uses it. The bucket must be created manually as a one-time prerequisite. Attempting `terraform init` without the bucket already existing will fail with a backend initialisation error.

---

## References

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/)
- [Terraform `for_each` Meta-Argument](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each)
- [AWS Security Group Rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule)

---

## Contact

Let's connect!

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/your-profile)