variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "region" {
  type        = string
  description = "Google Cloud region"
  default     = "europe-north2"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "sms_api_url" {
  type        = string
  description = "Url for SMS API"
}

variable "sheet_gid" {
  type        = number
  description = "Identifier for sheet tab"
}

variable "github_repo_owner" {
  type        = string
  description = "GitHub repository owner (username or organization)"
  default     = "astrberg"
}

variable "github_repo_name" {
  type        = string
  description = "GitHub repository name"
  default     = "project-x"
}

variable "jira_url" {
  type        = string
  description = "Jira Cloud base URL"
}

variable "jira_project_key" {
  type        = string
  description = "Jira Project Key"
}