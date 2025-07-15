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