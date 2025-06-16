import json
import requests
import os

# Slack webhook URL – store as environment variable or secret
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL")

def send_slack_notification(message):
    payload = {
        "text": f":rotating_light: *CloudGuard Auto-Heal Notification*\n{message}"
    }
    headers = {"Content-Type": "application/json"}
    
    response = requests.post(SLACK_WEBHOOK_URL, data=json.dumps(payload), headers=headers)
    if response.status_code == 200:
        print("Slack notification sent.")
    else:
        print("Failed to send notification:", response.text)

if __name__ == "__main__":
    msg = "Auto-remediation executed: S3 public access removed for bucket `example-bucket`."
    send_slack_notification(msg)
