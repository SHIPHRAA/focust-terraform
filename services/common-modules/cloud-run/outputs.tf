output "service_url" {
  description = "The URL of the Cloud Run service"
  value       = google_cloud_run_service.service.status[0].url
}

output "service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_service.service.name
}

output "service_location" {
  description = "The location of the Cloud Run service"
  value       = google_cloud_run_service.service.location
}

output "service_account_email" {
  description = "The service account email used by the service"
  value       = var.service_account_email != "" ? var.service_account_email : google_service_account.service_account[0].email
}

output "bucket_name" {
  description = "The storage bucket name (if created)"
  value       = var.create_storage_bucket ? google_storage_bucket.service_bucket[0].name : null
}

output "bucket_url" {
  description = "The storage bucket URL (if created)"
  value       = var.create_storage_bucket ? "gs://${google_storage_bucket.service_bucket[0].name}" : null
}

output "config_secret_id" {
  description = "The configuration secret ID (if created)"
  value       = var.create_config_secret ? google_secret_manager_secret.service_config[0].secret_id : null
}

output "artifact_repo_id" {
  description = "The Artifact Registry repository ID (if created)"
  value       = var.create_artifact_repo ? google_artifact_registry_repository.service_repo[0].repository_id : null
}

output "custom_domain_url" {
  description = "The custom domain URL (if configured)"
  value       = var.custom_domain != "" ? "https://${var.custom_domain}" : null
}

output "deployment_info" {
  description = "Complete deployment information"
  value = {
    service_name          = google_cloud_run_service.service.name
    service_url           = google_cloud_run_service.service.status[0].url
    service_location      = google_cloud_run_service.service.location
    service_account_email = var.service_account_email != "" ? var.service_account_email : google_service_account.service_account[0].email
    environment           = var.environment
    custom_domain         = var.custom_domain
    bucket_name           = var.create_storage_bucket ? google_storage_bucket.service_bucket[0].name : null
  }
}