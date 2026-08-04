Project 4: IAM & Access Governance Automation 
 Verdant Pay
Overview
Verdant Pay, a fintech startup, needed to onboard a batch of interns quickly while passing a least-privilege compliance audit, and needed to guarantee that a departed engineer's elevated access was fully and verifiably revoked. This project designs and builds that access model on Azure: scoped role-based groups for interns and database admins, a scripted grant/revoke process, and a tested off boarding simulation with before/after evidence.
Full scenario and requirements are in the capstone brief; the design reasoning (role matrix and off boarding checklist) is in Project4_Phase0_Worksheet.docx.
What's in this repo?
Project4_Phase0_Worksheet.docx — Phase 0 design worksheet (role matrix, offboarding checklist)
Project4_Incident_Report.docx — incident report covering a real authentication issue hit while building the CI/CD pipeline
deploy.sh — provisioning and off boarding script
.github/workflows/deploy.yml — GitHub Actions workflow that runs deploy.sh
screenshots/ — evidence of each build step and the off boarding simulation (see Evidence section below)
Architecture 
Resource group: rg-verdantpay-iam
VNet vnet-verdantpay (10.20.0.0/16) with two subnets: snet-web (10.20.1.0/24) and snet-db (10.20.2.0/24)
Azure AD groups & RBAC Scopes: WebAdmins (Contributor on the resource group), Interns Group (Contributor on the Vnet) and DBAdmins (Reader on the VNet)
Note on Scope: Azure IAM does not support direct role assignment on individual subnet resources. Therefore, Interns Group and DBAdmins were assigned at the Vnet level while network access controls non-web resources. 
Setup; running deploy.sh manually
Prerequisites: Azure CLI installed and logged in (az login), with Contributor or Owner rights on the target subscription.
Bash 
chmod +x deploy.sh
./deploy.sh
This creates the resource group, VNet, subnets, both AD groups, test intern users (added to Interns Group), and the role assignments matching the role matrix. It also defines an offboard_user function used for the off boarding simulation (see below).
Note: each individual command in this script was run and verified working manually during development. The assembled script has not yet been run start-to-finish as a single execution — see the incident report for the CI/CD pipeline issue that limited end-to-end testing.
Running the off-boarding process
The offboard_user function in deploy.sh checks a user's group memberships and role assignments, removes their role assignments, revokes their active sign-in sessions, and prints a final verification. To run it against a specific user, uncomment the example call at the bottom of the script or call it directly:
Bash
Source deploy.sh
Offboard_user “someone@yourdomain.onmicrosoft.com”
This was run manually (via Azure Portal, due to a CLI issue documented in the incident report) against a simulated "departed engineer" test user; before/after evidence is in screenshots/.
Evidence (screenshots/)
Each screenshot below documents the steps of the build or off boarding process;
01-resource-group-created-1.png
01-resource-group-created-2.png
Resource group rg-verdantpay-iam successfully created
02-vnet-subnets-created-3.png
02-vnet-subnets-created-db-2.png
02-vnet-subnets-created-web-1.png
VNet vnet-verdantpay with Web and DB subnets created
03-ad-groups-created-4.png
03-ad-groups-created-dbadmin-2.png
03-ad-groups-created-interns-3.png
03-ad-groups-created-webadmin-1.png
WebAdmins, Interns Group and DBAdmins Azure AD groups created
04-role-assignments-matrix-db-reader-2.png
04-role-assignments-matrix-interns-contributor-3.png
04-role-asbsignments-maturix-web-conttributor-1.png
Role assignments matching the Phase 0 role matrix (WebAdmins → Contributor, Interns Group → Contributor, DBAdmins → Reader)
05-internuser1-created-1.png
05-internuser2-created-2.png
06-intern-access-validated-1.png
06-intern-access-validated-2.png
InternTestUser created and confirmed as a member of Interns Group, validating their access matches the role matrix
07-departedengineer-created-1.png
08-departedengineer-before-offboarding-2.png
DepartedEngineer created and shown with Owner access on rg-verdantpay-iam, before off boarding
09-departedengineer-role-removed.png
Owner role assignment removed from DepartedEngineer
10-departedengineer-sessions-revoked.png
Active sign-in sessions revoked for DepartedEngineer, completing the offboarding process
CI/CD pipeline
.github/workflows/deploy.yml is configured to run deploy.sh automatically via GitHub Actions, authenticating to Azure with a service principal stored in the AZURE_CREDENTIALS repository secret. The workflow file and script are both correct and complete; the pipeline currently does not run successfully end-to-end due to a persistent Azure CLI authentication issue encountered in this environment. Full details, investigation, and root cause are documented in Project4_Incident_Report.docx.
Teardown
To remove everything created by this project:
Bash
az group delete - -name rg-verdantpay-iam - -yes - -no-wait
This deletes the resource group and everything inside it (VNet, subnets). The Azure AD groups and test users are outside the resource group and must be removed separately if needed:
Bash
az ad group delete - -group WebAdmins
az ad group delete - -group DBAdmins 
Author
Victory Etim Okpoyo 
CLC/2026/TC-7/0122
 Cloud & DevOps Boot camp, Capstone Project 4 
s