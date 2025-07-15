output "frontend_url" {
  description = "The frontend service URL"
  value       = module.frontend.service_url
}

output "frontend_custom_url" {
  description = "The frontend custom domain URL"
  value       = module.frontend.custom_domain_url
}

output "frontend_bucket_name" {
  description = "The frontend assets bucket name"
  value       = module.frontend.bucket_name
}

output "frontend_service_account" {
  description = "The frontend service account email"
  value       = module.frontend.service_account_email
}

output "frontend_deployment_info" {
  description = "Complete frontend deployment information"
  value       = module.frontend.deployment_info
}