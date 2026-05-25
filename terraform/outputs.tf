output "receive_incoming_sms_name" {
  value       = google_cloudfunctions2_function.receive_incoming_sms.name
  description = "Name of the receive incoming Cloud Function"
}

output "receive_incoming_sms_url" {
  value       = google_cloudfunctions2_function.receive_incoming_sms.service_config[0].uri
  description = "Trigger URL for the receiving Cloud Function"
  sensitive   = true
}

output "brain_dump_idea_name" {
  value       = google_cloudfunctions2_function.brain_dump_idea.name
  description = "Name of the process Cloud Function"
}

output "brain_dump_idea_url" {
  value       = google_cloudfunctions2_function.brain_dump_idea.service_config[0].uri
  description = "Trigger URL for the processing Cloud Function"
  sensitive   = true
}

output "brain_dump_todo_name" {
  value       = google_cloudfunctions2_function.brain_dump_todo.name
  description = "Name of the brain dump todo Cloud Function"
}

output "brain_dump_todo_url" {
  value       = google_cloudfunctions2_function.brain_dump_todo.service_config[0].uri
  description = "Trigger URL for the brain dump todo Cloud Function"
  sensitive   = true
}

output "firestore_database" {
  value       = google_firestore_database.database.name
  description = "Firestore database name"
}

output "service_account_email" {
  value       = google_service_account.function_account.email
  description = "Service account email for Cloud Function"
  sensitive   = true
}

output "terraform_state_bucket" {
  value       = google_storage_bucket.terraform_state_bucket.name
  description = "GCS bucket for Terraform state storage"
}

output "workload_identity_provider" {
  value       = google_iam_workload_identity_pool_provider.github_provider.name
  description = "Workload Identity Provider name for GitHub Actions authentication"
  sensitive   = true
}

output "github_actions_service_account" {
  value       = google_service_account.github_actions_sa.email
  description = "Service account email for GitHub Actions"
  sensitive   = true
}
