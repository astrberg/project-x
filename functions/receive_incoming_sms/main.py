import logging
import os
import secrets
from flask import abort

import functions_framework
import google.cloud.logging
from google.cloud import firestore

logging_client = google.cloud.logging.Client()
logging_client.setup_logging()

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

DB = firestore.Client(database="main")


"""
Test Payload
curl -X POST receive_incoming_sms_url \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "id=abc123&from=%2B1234567890&to=%2B0987654321&message=Hello%20World&direction=incoming&created=2024-01-01T12%3A00%3A00Z"
"""


@functions_framework.http
def receive_incoming_sms(request):
    """HTTP Cloud Function for receiving incoming SMS webhooks."""

    if not request.form:
        return abort(400)

    key = request.args.get("key")
    actual_key = os.environ.get("WEBHOOK_KEY")

    if not key or not actual_key or not secrets.compare_digest(key, actual_key):
        logger.warning("Unauthorized access attempt to incoming SMS webhook")
        return abort(401)

    sms_payload = request.form.to_dict(flat=True)

    is_incoming_sms = str(sms_payload.get("direction", "")).lower() == "incoming"
    if is_incoming_sms:
        logger.info(
            {
                "message": "Incoming SMS webhook received",
                "direction": sms_payload.get("direction"),
                "from": sms_payload.get("from"),
                "to": sms_payload.get("to"),
                "sms_id": sms_payload.get("id"),
            }
        )
        is_todo = str(sms_payload.get("message", "")).strip().lower().startswith("todo:")
        collection_name = "incoming_todo" if is_todo else "incoming_sms"
        sms_collection = DB.collection(collection_name)
        sms_document = (
            sms_collection.document(sms_payload.get("id"))
            if sms_payload.get("id")
            else sms_collection.document()
        )
        sms_document.set(sms_payload)
        logger.info(
            {
                "message": "Stored incoming SMS in main",
                "collection": collection_name,
                "document_id": sms_document.id,
            }
        )

        return "", 200

    return abort(400)
