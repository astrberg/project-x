import logging
import os

import functions_framework
from cloudevents.http import CloudEvent
from google.cloud import firestore
from google import genai
from google.genai import types
import requests
from googleapiclient.discovery import build
import google.auth

from constants import IDEA_SCHEMA

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

DB = firestore.Client(database="main")

GEMINI_CLIENT = genai.Client(api_key=os.environ.get("GEMINI_API_KEY"))
MODEL = "gemini-3.1-flash-lite"
TOOL = types.Tool(
    function_declarations=[
        types.FunctionDeclaration(
            name="extract_idea",
            description="Extract structured project idea info from text.",
            parameters=IDEA_SCHEMA,
        )
    ]
)
CONFIG = types.GenerateContentConfig(
    tools=[TOOL],
    tool_config=types.ToolConfig(function_calling_config=types.FunctionCallingConfig(mode="ANY")),
    system_instruction="""
You are a pragmatic Venture Architect. Your goal is to evaluate startup ideas and provide a high-density SMS receipt.

1. **Reaction**: Generate a unique, one-sentence reaction to the idea. Be sharp, technical, and objective. Avoid AI fluff (e.g., "exciting," "game-changer"). 
2. **The SMS Format**: Combine your reaction and metrics into a 'formatted_sms' field using this EXACT template:
   [Reaction] Pitch: [Short Pitch]. Effort: [Complexity] | $$: [1-5]/5. Stack: [3 words].

3. **Constraints**:
   - The 'formatted_sms' MUST be under 160 characters.
   - Use 2026 market context.
   - If the idea is weak, be candid in the reaction.
""",
)
SMS_API_URL = os.environ.get("SMS_API_URL")
SMS_API_USERNAME = os.environ.get("SMS_API_USERNAME")
SMS_API_PASSWORD = os.environ.get("SMS_API_PASSWORD")

CREDENTIALS, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/spreadsheets"])
SHEETS_CLIENT = build("sheets", "v4", credentials=CREDENTIALS)
SHEET_ID = os.environ.get("SHEET_ID")
SHEET_GID = os.environ.get("SHEET_GID")


@functions_framework.cloud_event
def brain_dump_idea(cloud_event: CloudEvent):
    """Cloud Function for brain dumping idea into Google Sheet in combination with Gemini"""
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
    created_at = document_data.get("created", "")

    if not incoming_message or not incoming_from or not incoming_to or not created_at:
        logger.warning(f"Invalid data in {relative_path}. Skipping.")
        return

    response_model = GEMINI_CLIENT.models.generate_content(
        model=MODEL,
        contents=f"Extract idea details from this message: {incoming_message}",
        config=CONFIG,
    )

    call = response_model.candidates[0].content.parts[0].function_call

    if not call or not call.args:
        logger.warning("Gemini did not return any structured data.")
        return

    args = dict(call.args)

    doc_ref.update({MODEL: args, "model_updated_at": firestore.SERVER_TIMESTAMP})

    logger.info(f"Updated document {relative_path}")

    formatted_sms = args.get("formatted_sms", "Idea processed.")
    outgoing_sms = formatted_sms[:160]

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

    row_data = [
        created_at,
        incoming_from,
        incoming_message,
        formatted_sms,
        args.get("ai_reaction", ""),
        args.get("one_sentence_pitch", ""),
        args.get("estimated_complexity", ""),
        args.get("monetization_potential", ""),
        args.get("tech_stack_suggestions", ""),
        args.get("core_problem", ""),
    ]

    batch_update_request = {
        "requests": [
            # STEP A: Insert a blank row at Row 2 (index 1) to push data down[cite: 1]
            {
                "insertDimension": {
                    "range": {"sheetId": SHEET_GID, "dimension": "ROWS", "startIndex": 1, "endIndex": 2},
                    "inheritFromBefore": False,
                }
            },
            # STEP B: Fill that new Row 2 with your startup idea data[cite: 1]
            {
                "updateCells": {
                    "rows": [
                        {
                            "values": [
                                {"userEnteredValue": {"stringValue": str(val)}} for val in row_data
                            ]
                        }
                    ],
                    "fields": "userEnteredValue",
                    "start": {"sheetId": SHEET_GID, "rowIndex": 1, "columnIndex": 0},
                }
            },
        ]
    }

    SHEETS_CLIENT.spreadsheets().batchUpdate(
        spreadsheetId=SHEET_ID, body=batch_update_request
    ).execute()

    logger.info(f"Successfully updated sheet id {SHEET_ID}")

    return
