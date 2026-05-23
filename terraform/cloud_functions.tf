resource "google_storage_bucket" "functions_source" {
  project       = var.project_id
  name          = "${var.project_id}-function-source-${var.environment}"
  location      = var.region
  force_destroy = true
}

data "archive_file" "function_receive_incoming_sms_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/receive_incoming_sms"
  output_path = "${path.module}/../dist/receive_incoming_sms"
}

resource "google_storage_bucket_object" "function_receive_incoming_sms_zip" {
  name   = "receive-${data.archive_file.function_receive_incoming_sms_zip.output_md5}.zip"
  bucket = google_storage_bucket.functions_source.name
  source = data.archive_file.function_receive_incoming_sms_zip.output_path

  depends_on = [google_storage_bucket.functions_source]
}

data "archive_file" "function_brain_dump_idea_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../functions/brain_dump_idea"
  output_path = "${path.module}/../dist/brain_dump_idea"
}

resource "google_storage_bucket_object" "function_process_incoming_zip" {
  name   = "process-${data.archive_file.function_brain_dump_idea_zip.output_md5}.zip"
  bucket = google_storage_bucket.functions_source.name
  source = data.archive_file.function_brain_dump_idea_zip.output_path

  depends_on = [google_storage_bucket.functions_source]
}

resource "google_service_account" "cloud_build_service_account" {
  project      = var.project_id
  account_id   = "cloud-build-sa"
  display_name = "Cloud Build service account for Cloud Functions"
}

resource "google_cloudfunctions2_function" "receive_incoming_sms" {
  project  = var.project_id
  name     = "receive-incoming-sms"
  location = "europe-west1" # change when available

  description = "Receive incoming SMS webhooks"
  build_config {
    runtime     = "python312"
    entry_point = "receive_incoming_sms"
    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = google_storage_bucket_object.function_receive_incoming_sms_zip.name
      }
    }
    service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.cloud_build_service_account.email}"
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 60
    service_account_email = google_service_account.function_account.email

    secret_environment_variables {
      key        = "WEBHOOK_KEY"
      secret     = google_secret_manager_secret.webhook_key.secret_id
      version    = "latest"
      project_id = var.project_id
    }
  }

  depends_on = [
    google_storage_bucket.functions_source,
    google_storage_bucket_object.function_receive_incoming_sms_zip,
  ]
}

resource "google_cloudfunctions2_function" "brain_dump_idea" {
  project  = var.project_id
  name     = "brain_dump_idea"
  location = "europe-west1" # change when available

  description = "Process incoming SMS"
  build_config {
    runtime     = "python312"
    entry_point = "brain_dump_idea"
    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = google_storage_bucket_object.function_process_incoming_zip.name
      }
    }
    service_account = "projects/${var.project_id}/serviceAccounts/${google_service_account.cloud_build_service_account.email}"
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "512M"
    timeout_seconds       = 60
    service_account_email = google_service_account.function_account.email

    secret_environment_variables {
      key        = "GEMINI_API_KEY"
      secret     = google_secret_manager_secret.gemini_api_key.secret_id
      version    = "latest"
      project_id = var.project_id
    }

    secret_environment_variables {
      key        = "SMS_API_USERNAME"
      secret     = google_secret_manager_secret.sms_api_username.secret_id
      version    = "latest"
      project_id = var.project_id
    }

    secret_environment_variables {
      key        = "SMS_API_PASSWORD"
      secret     = google_secret_manager_secret.sms_api_password.secret_id
      version    = "latest"
      project_id = var.project_id
    }

    secret_environment_variables {
      key        = "SHEET_ID"
      secret     = google_secret_manager_secret.sheet_id.secret_id
      version    = "latest"
      project_id = var.project_id
    }

    environment_variables = {
      SMS_API_URL = var.sms_api_url
      SHEET_GID   = var.sheet_gid
    }
  }

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
      value     = "incoming_sms/{docId}"
      operator  = "match-path-pattern"
    }
  }

  depends_on = [
    google_storage_bucket.functions_source,
    google_storage_bucket_object.function_process_incoming_zip,
  ]

}

resource "google_cloud_run_service_iam_member" "unauthenticated_invoker" {
  project  = google_cloudfunctions2_function.receive_incoming_sms.project
  location = google_cloudfunctions2_function.receive_incoming_sms.location
  service  = google_cloudfunctions2_function.receive_incoming_sms.name

  role   = "roles/run.invoker"
  member = "allUsers"
}

resource "google_cloud_run_service_iam_member" "process_invoker" {
  project  = google_cloudfunctions2_function.brain_dump_idea.project
  location = google_cloudfunctions2_function.brain_dump_idea.location
  service  = google_cloudfunctions2_function.brain_dump_idea.service_config[0].service

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_service_account" "function_account" {
  project    = var.project_id
  account_id = "functions-service-account"
}

resource "google_project_iam_member" "function_firestore_access" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_project_iam_member" "function_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.function_account.email}"
}

resource "google_project_iam_member" "cloud_build_sa_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloud_build_service_account.email}"
}

resource "google_project_iam_member" "cloud_build_sa_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.cloud_build_service_account.email}"
}
