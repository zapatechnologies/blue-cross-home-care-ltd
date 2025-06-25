# Terraform outputs

output "cloud_run_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.main.status[0].url
}

output "database_connection_name" {
  description = "Database connection name"
  value       = google_sql_database_instance.main.connection_name
}

output "domain_url" {
  description = "Custom domain URL"
  value       = "https://${var.domain_name}"
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}
