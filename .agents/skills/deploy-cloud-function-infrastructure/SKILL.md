---
name: deploy-cloud-function-infrastructure
description: Use when managing Terraform configurations and deploying cloud functions.
---

# Deploy Cloud Function Infrastructure

Use this skill to map your Python cloud functions to infrastructure resources using Terraform. Deployment is handled exclusively via GitHub Actions.

## When to use this skill

- Registering a new cloud function resource in Terraform.
- Modifying environment variables, triggers, or permissions for an existing function.

## How to use it

### 1. Terraform Configuration

- Navigate to the terraform/ directory.
- Update the relevant .tf files to include or modify the cloud function resource.
- Ensure the source path explicitly points to the correct subfolder within functions/.
- Do not add comments inside the .tf files.

### 2. Standard Event Trigger Format

When configuring event-driven Cloud Functions (e.g. Firestore document triggers), strictly follow this Eventarc pattern:

```hcl
  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.firestore.document.v1.created"
    retry_policy   = "RETRY_POLICY_DO_NOT_RETRY"

    service_account_email = google_service_account.function_account.email

    event_filters {
      attribute = "database"
      value     = "main"
    }

    event_filters {
      attribute = "document"
      value     = "collection_name/{docId}"
      operator  = "match-path-pattern"
    }
  }
```

### 3. Deployment Execution

- Do not run local deployment commands (terraform apply).
- The GitHub Actions workflow will automatically execute the Terraform deployment.
- Do not commit and push changes.
