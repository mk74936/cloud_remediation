# 🌐 CloudGuard Auto-Heal

An automated cross-cloud remediation framework to detect and fix misconfigurations in AWS and Azure environments, using Infrastructure-as-Code, serverless automation, and policy-driven actions.

---

## 🛠 Project Features

- 🔒 Detect insecure configurations using:
  - AWS Config Rules (e.g., public S3 access)
  - Azure Policy Definitions (e.g., RDP open on NSGs)
- 🔁 Automatically remediate using:
  - AWS Lambda + EventBridge + S3 ACL modification
  - Azure Automation Runbooks (PowerShell)
- 🚨 Alert escalation via:
  - Slack notifications
  - Azure DevOps ticket creation
- 🧪 Includes simulated test cases for safe demo

---

## 📁 Folder Structure

cloudguard-autoheal/
│
├── terraform/ # Infra-as-Code for AWS & Azure
│ ├── aws/ # AWS Config, Lambda, EventBridge
│ └── azure/ # Azure Policy, Runbooks, Monitor Alerts
│
├── compliance_policies/ # AWS Config rules, Azure policy JSONs
├── auto_remediation/ # Python & PowerShell remediation scripts
├── escalation/ # Slack + DevOps escalation
├── misconfig_scanner/ # (Future) Policy scanner scripts
├── alerts/ # Simulated event payloads & misconfigurations
├── ci_cd/ # Bitbucket Pipelines (optional)
└── README.md



---

## 🚀 Setup Instructions

### ✅ Prerequisites

- AWS CLI configured
- Azure CLI signed in
- Terraform v1.5+ installed
- Python 3.10+ environment
- (Optional) Azure DevOps & Slack Webhook tokens

### 🔹 Step 1: Deploy AWS Infra

```bash
cd terraform/aws
terraform init
terraform apply


This sets up:

AWS Config + S3 delivery

Remediation Lambda + IAM

EventBridge rule for non-compliance

 Step 2: Deploy Azure Infra

 cd terraform/azure
terraform init
terraform apply


🧪 Testing
🟢 AWS Test (Simulated)

cd alerts/
aws lambda invoke \
  --function-name cloudguard-revoke-s3-public-access \
  --payload file://aws_simulated_event.json \
  output.json

🟢 Azure Test (Simulated NSG)

cd terraform/azure
terraform apply -target=azurerm_network_security_group.rdp_test_nsg

Monitor should detect this and trigger runbook.

🧑‍💻 Slack & DevOps Integration
Set your environment variables before running escalation scripts:

export SLACK_WEBHOOK_URL="..."
export ADO_ORG="your-org"
export ADO_PROJECT="your-project"
export ADO_TOKEN_BASE64=$(echo -n ":<PAT>" | base64)


Then run:

python escalation/notify_slack.py
python escalation/raise_devops_ticket.py


s