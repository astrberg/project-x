resource "google_secret_manager_secret" "webhook_key" {
  secret_id = "webhook-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "gemini-api-key"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "sms_api_username" {
  secret_id = "sms-api-username"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "sms_api_password" {
  secret_id = "sms-api-password"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "sheet_id" {
  secret_id = "sheet-id"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}


resource "google_secret_manager_secret_iam_member" "secret_access_webhook_key" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.webhook_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_gemini_api_key" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.gemini_api_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_sms_api_username" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.sms_api_username.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_sms_api_password" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.sms_api_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_sheet_id" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.sheet_id.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_secret_manager_secret" "jira_email" {
  secret_id = "jira-email"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret" "jira_api_token" {
  secret_id = "jira-api-token"

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_secret_manager_secret_iam_member" "secret_access_jira_email" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.jira_email.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_jira_api_token" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.jira_api_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_account.email}"
}
