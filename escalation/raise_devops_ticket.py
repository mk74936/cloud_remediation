import requests
import json
import os

# Set these as environment variables or replace with hardcoded values for testing
ADO_ORG = os.getenv("ADO_ORG")  # e.g., "myorg"
ADO_PROJECT = os.getenv("ADO_PROJECT")  # e.g., "cloudguard"
ADO_PAT = os.getenv("ADO_PAT")  # Azure DevOps personal access token

def create_work_item(title, description):
    url = f"https://dev.azure.com/{ADO_ORG}/{ADO_PROJECT}/_apis/wit/workitems/$Bug?api-version=6.0"
    headers = {
        "Content-Type": "application/json-patch+json",
        "Authorization": f"Basic {os.getenv('ADO_TOKEN_BASE64')}"
    }

    payload = [
        {
            "op": "add",
            "path": "/fields/System.Title",
            "value": title
        },
        {
            "op": "add",
            "path": "/fields/System.Description",
            "value": description
        }
    ]

    response = requests.post(url, headers=headers, data=json.dumps(payload))
    if response.status_code == 200 or response.status_code == 201:
        print("Azure DevOps ticket created.")
    else:
        print("Failed to create work item:", response.text)

if __name__ == "__main__":
    title = "CloudGuard: S3 Bucket Public Access Detected"
    description = "A bucket was found non-compliant and has been remediated. Please review resource settings."
    create_work_item(title, description)
