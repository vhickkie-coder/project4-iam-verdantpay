 Project 4: IAM & Access Governance Automation — Verdant Pay

Overview
A fintech startup, Verdant Pay, needed to onboard a batch of interns for a 6-week sprint with immediate, frictionless access while maintaining strict least-privilege compliance for an upcoming audit. Additionally, the company required a verifiable, scripted offboarding process to guarantee that a departed engineer’s elevated access was fully revoked.

This project designs, automates, and validates:
* Azure Resource Group and VNet/Subnet segmentation.
* Scoped Role-Based Access Control (RBAC) groups for Web and Database administrators.
* An automated deployment script (`deploy.sh`) handling provisioning and offboarding.
* A GitHub Actions CI/CD pipeline enforcing automated execution.


Repository Structure
```text
├── .github/workflows/
│   └── deploy.yml          # GitHub Actions CI/CD pipeline configuration
├── screenshots/            # Evidence logs for build steps and offboarding simulation
├── deploy.sh               # End-to-end provisioning and offboarding script
├── Project4_Phase0_Worksheet-2.docx  # Phase 0 design worksheet (Role matrix & checklist)
├── Project4_Incident_Report-1.docx   # Incident report detailing troubleshooting & resolution
└── README.md               # Project documentation
Architecture & Design Summary
•	Resource Group: rg-verdantpay-iam
•	Region: South Africa North
•	Virtual Network: vnet-verdantpay (10.20.0.0/16) 
o	Web Subnet (snet-web): 10.20.1.0/24 (Assigned to WebAdmins and Interns)
o	DB Subnet (snet-db): 10.20.2.0/24 (Assigned to DBAdmins)
Note on Scope: Because Azure IAM does not support direct role assignments on individual subnet resources, roles were scoped at the VNet level with targeted permissions matching the Phase 0 role matrix, preventing cross-tier access into database security zones. Time-bound expiry for the Interns role is enforced procedurally via offboarding at sprint end.

Setup & Execution Instructions
Prerequisites
o	Azure CLI installed and authenticated (az login) with Contributor or Owner privileges on your target subscription.
o	Bash shell environment (Linux, macOS, or Git Bash).
Local Execution
1.	Clone the repository 
Git clone [https://github.com/vhkkie-coder/project4-iam-verdantpay.git](https://github.com/vhkkie-coder/project4-iam-verdantpay.git)
Cd project4-iam-verdantpay
2.	Grant execution permission to the script
Chmod +x deploy.sh
3.	Run the deployment Script 
./deploy.sh
CI/CD Pipeline (deploy.yml)
The workflow automatically triggers on pushes to the main branch or via manual dispatch (workflow_dispatch). It authenticates via an Azure Service Principal stored in GitHub Secrets (AZURE_CREDENTIALS) and executes deploy.sh in a secure Ubuntu runner environment.
Evidence & Verification
All deployment checkpoints and offboarding validation steps have been captured and stored in the screenshots/ directory, including:
Resource Group Creation: rg-verdantpay-iam successfully provisioned.
VNet Subnets: snet-web and snet-db created with correct CIDR blocks.
Azure AD Groups: WebAdmins, Interns, and DBAdmins established.
Role Assignments: Scoped RBAC mappings verified against the role matrix.
Offboarding Simulation: Execution of offboard_user successfully wiping group memberships, deleting direct role assignments, and disabling the account of the simulated departed engineer.
Author
Victory Etim Okpoyo 
CLC/2026/TC-7/0122
 Cloud & DevOps Boot camp, Capstone Project 4 
 