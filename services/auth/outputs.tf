output "auth_url" {
  description = "The auth service URL"
  value       = module.auth.service_url
}

output "auth_service_account" {
  description = "The auth service account email"
  value       = module.auth.service_account_email
}

output "auth_config_secret_id" {
  description = "The auth configuration secret ID"
  value       = module.auth.config_secret_id
}

output "jwt_secret_id" {
  description = "The JWT secret ID"
  value       = google_secret_manager_secret.jwt_secret.secret_id
}

output "auth_deployment_info" {
  description = "Complete auth deployment information"
  value       = module.auth.deployment_info
}