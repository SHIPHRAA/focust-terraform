output "backend_url" {
  description = "The backend service URL"
  value       = module.backend.service_url
}

output "backend_bucket_name" {
  description = "The backend data bucket name"
  value       = module.backend.bucket_name
}

output "backend_service_account" {
  description = "The backend service account email"
  value       = module.backend.service_account_email
}

output "backend_config_secret_id" {
  description = "The backend configuration secret ID"
  value       = module.backend.config_secret_id
}

output "backend_deployment_info" {
  description = "Complete backend deployment information"
  value       = module.backend.deployment_info
}

output "database_instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = var.create_database ? google_sql_database_instance.backend_db[0].name : null
}

output "database_connection_name" {
  description = "The Cloud SQL instance connection name"
  value       = var.create_database ? google_sql_database_instance.backend_db[0].connection_name : null
}

output "database_ip_address" {
  description = "The IP address of the Cloud SQL instance"
  value       = var.create_database ? google_sql_database_instance.backend_db[0].public_ip_address : null
  sensitive   = true
}

output "database_secret_id" {
  description = "The Secret Manager secret ID for database URL"
  value       = var.create_database ? google_secret_manager_secret.database_url[0].secret_id : null
}