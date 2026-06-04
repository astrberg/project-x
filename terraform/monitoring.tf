resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Email Notification Channel"
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "unauthorized_sms_webhook_alert" {
  project      = var.project_id
  display_name = "Unauthorized SMS Webhook Access Attempt Alert"
  combiner     = "OR"

  conditions {
    display_name = "Unauthorized SMS Webhook Log Match"

    condition_matched_log {
      filter = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${google_cloudfunctions2_function.receive_incoming_sms.name}\" AND severity=\"WARNING\" AND \"Unauthorized access attempt to incoming SMS webhook\""
    }
  }

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name
  ]
}
