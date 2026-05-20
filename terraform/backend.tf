resource "google_storage_bucket" "terraform_state_bucket" {
  project  = var.project_id
  name     = "project-x-terraform-state-dev"
  location = var.region

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

terraform {
  backend "gcs" {
    bucket = "project-x-terraform-state-dev"
    prefix = "terraform/state"
  }

  required_version = ">= 1.15.3"
}
