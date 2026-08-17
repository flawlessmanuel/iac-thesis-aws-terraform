\# IaC Thesis — AWS Three-Tier Infrastructure via Terraform



Infrastructure for an engineering thesis ("Design and Implementation of Cloud

Infrastructure in the Infrastructure as Code Model Using Terraform and AWS",

AHE Łódź) demonstrating a reproducible, version-controlled AWS environment

provisioned entirely through Terraform.



\## Architecture



\- \*\*VPC\*\* `10.0.0.0/16`, spanning two Availability Zones (`eu-north-1a`, `eu-north-1b`)

\- \*\*Application Load Balancer\*\* in the public subnets, routing HTTP traffic to an Auto Scaling Group

\- \*\*EC2 (Auto Scaling Group)\*\* running Apache httpd, `t3.micro`, desired capacity 2 / max 3

\- \*\*RDS MySQL 8.0\*\* (`db.t3.micro`), private subnets, encrypted at rest, not publicly accessible

\- \*\*18 resources\*\* total on a clean apply



EC2 instances are placed in the public subnets rather than behind a NAT Gateway,

as a deliberate cost trade-off — see the thesis (§4.2) for the full rationale.



\## Prerequisites



\- Terraform >= 1.11 (required for S3 native state locking via `use\_lockfile`)

\- AWS CLI, configured with credentials that can create VPC/EC2/RDS/ALB resources

\- An S3 bucket for remote state (bootstrap steps are documented at the top of `backend.tf`)



\## Usage



```bash

terraform init

terraform plan

terraform apply

\# ...

terraform destroy

```



Set the required variables (`db\_password`, `allowed\_ssh\_cidr`) via a

`terraform.tfvars` file — see `terraform.tfvars.example` — or environment

variables. `terraform.tfvars` is git-ignored and must never be committed.



\## Repository structure

terraformthesisproject/

\->provider.tf

\->variables.tf

\->backend.tf

\->network.tf

\->security.tf

\->compute.tf

\->database.tf

\->outputs.tf

\->terraform.tfvars.example



\## Security



\- SSH (port 22) restricted to a single trusted CIDR via `allowed\_ssh\_cidr`, not open to the internet

\- Database credential passed as a `sensitive` Terraform variable (masks CLI/UI output — note this does \*\*not\*\* encrypt the value inside the state file, so `terraform.tfstate` should always be treated as sensitive and never committed)

\- RDS: `storage\_encrypted = true`, `publicly\_accessible = false`



\## CI



A GitHub Actions workflow (`.github/workflows/terraform-ci.yml`) runs

`terraform fmt -check`, `terraform validate`, and `terraform plan` on every

push and pull request to `main`. It is intentionally read-only — it never

runs `apply` or `destroy`.



\## Known limitations



\- No NAT Gateway; EC2 instances have public IPs (cost trade-off, see thesis §4.2/§6.2)

\- RDS is a single instance (`multi\_az` not enabled) — not automatically fault-tolerant across AZs

\- CI validates and plans only; `apply` is run manually, by design



