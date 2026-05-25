import logging
import os

import functions_framework
from cloudevents.http import CloudEvent
from google.cloud import firestore
import requests

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

DB = firestore.Client(database="main")

SMS_API_URL = os.environ.get("SMS_API_URL")
SMS_API_USERNAME = os.environ.get("SMS_API_USERNAME")
SMS_API_PASSWORD = os.environ.get("SMS_API_PASSWORD")

JIRA_URL = os.environ.get("JIRA_URL")
JIRA_PROJECT_KEY = os.environ.get("JIRA_PROJECT_KEY")
JIRA_EMAIL = os.environ.get("JIRA_EMAIL")
JIRA_API_TOKEN = os.environ.get("JIRA_API_TOKEN")


@functions_framework.cloud_event
def brain_dump_todo(cloud_event: CloudEvent):
    subject = cloud_event.get("subject")

    if not subject:
        logger.error("CloudEvent did not contain a subject header.")
        return

    relative_path = subject.split("documents/")[1]
    doc_ref = DB.document(relative_path)

    snapshot = doc_ref.get()
    if not snapshot.exists:
        logger.warning(f"Document {relative_path} no longer exists.")
        return

    document_data = snapshot.to_dict()
    incoming_message = document_data.get("message", "")
    incoming_from = document_data.get("from", "")
    incoming_to = document_data.get("to", "")

    if not incoming_message or not incoming_from or not incoming_to:
        logger.warning(f"Invalid data in {relative_path}. Skipping.")
        return

    message_text = incoming_message.strip()
    todo_text = message_text[5:].strip()

    jira_issue_endpoint = f"{JIRA_URL.rstrip('/')}/rest/api/3/issue"
    jira_payload = {
        "fields": {
            "project": {"key": JIRA_PROJECT_KEY},
            "summary": todo_text,
            "description": {
                "type": "doc",
                "version": 1,
                "content": [
                    {
                        "type": "paragraph",
                        "content": [
                            {"text": f"Todo created via SMS from {incoming_from}.", "type": "text"}
                        ],
                    }
                ],
            },
            "issuetype": {"name": "Story"},
        }
    }

    jira_response = requests.post(
        jira_issue_endpoint,
        auth=(JIRA_EMAIL, JIRA_API_TOKEN),
        headers={"Accept": "application/json", "Content-Type": "application/json"},
        json=jira_payload,
    )

    jira_response.raise_for_status()
    jira_data = jira_response.json()
    jira_key = jira_data.get("key")
    jira_id = jira_data.get("id")

    doc_ref.update(
        {
            "todo_text": todo_text,
            "status": "created",
            "jira_key": jira_key,
            "jira_id": jira_id,
            "jira_response": jira_data,
            "processed_at": firestore.SERVER_TIMESTAMP,
        }
    )

    logger.info(f"Updated todo document {relative_path} with Jira key {jira_key}")

    outgoing_sms = f"Todo saved as Jira story [{jira_key}]: {todo_text}"
    if len(outgoing_sms) > 160:
        outgoing_sms = outgoing_sms[:157] + "..."

    response_sms = requests.post(
        SMS_API_URL,
        auth=(SMS_API_USERNAME, SMS_API_PASSWORD),
        data={
            "from": incoming_to,
            "to": incoming_from,
            "message": outgoing_sms,
        },
    )

    response_sms.raise_for_status()
    response_sms_json = response_sms.json()
    doc_ref.update(
        {
            "sms_receipt": response_sms_json,
            "sms_receipt_updated_at": firestore.SERVER_TIMESTAMP,
        }
    )

    logger.info(f"SMS sent with id {response_sms_json.get('id')}")
    return
