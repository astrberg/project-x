---
name: verify-secret-hygiene
description: Use when auditing the codebase to prevent sensitive information leaks in a public GitHub repository.
---

# Verify Secret Hygiene

Use this skill to audit the codebase for sensitive credentials, keys, tokens, or configuration leaks, and ensure standard Git hygiene before publishing to a public repository.

## When to use this skill

- Before committing new features or infrastructure additions.
- Prior to pushing the codebase to a public remote repository.
- During any security review task.

## How to use it

### 1. Verification Checklist

Strictly check for the following patterns and ensure they are absent from the codebase:

- **Hardcoded API Keys / Tokens**: No credentials (e.g., Gemini API keys, Slack webhook keys, Twilio/SMS API tokens, Jira API keys/emails) should be hardcoded in `.py`, `.tf`, `.toml`, or `.json` files.
- **Gitignored Files**: Ensure all sensitive local configurations are declared in `.gitignore` (e.g., `terraform.tfvars`, `.env`, `google-cloud-key.json`, `.terraform/`, `*.tfstate`).
- **Static GCP Keys**: Confirm that OIDC/Workload Identity Federation is used instead of static service account JSON key files.

### 2. Auditing Commands

Run the following checks to identify potential secret patterns:

- Search for potential key keywords:
  ```bash
  git grep -i -E "api_key|password|secret|token|auth"
  ```
- Check git status to ensure untracked sensitive files are not accidentally staged:
  ```bash
  git status
  ```

### 3. Remediating Leaks

If a sensitive parameter is found:
1. **Move to Environment Variables**: Load the parameter dynamically using `os.environ.get("PARAMETER_NAME")` in Python.
2. **Mount via Google Secret Manager**: Define the secret and its IAM accessor in Terraform, then mount it into the Cloud Function's secret environment variables block in `cloud_functions.tf`.
3. **Declare Variable Placeholders**: For non-secret localized environment variables, declare them in `variables.tf` and place local overrides inside the gitignored `terraform.tfvars`.
