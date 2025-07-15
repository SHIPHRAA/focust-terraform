output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

output "artifact_registry_repository_id" {
  description = "The shared Artifact Registry repository ID"
  value       = google_artifact_registry_repository.shared_repo.repository_id
}

output "artifact_registry_url" {
  description = "The shared Artifact Registry URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.shared_repo.repository_id}"
}

output "infrastructure_service_account_email" {
  description = "The infrastructure service account email"
  value       = google_service_account.infrastructure_sa.email
}

output "shared_assets_bucket_name" {
  description = "The shared assets bucket name"
  value       = google_storage_bucket.shared_assets.name
}

output "shared_config_secret_id" {
  description = "The shared configuration secret ID"
  value       = google_secret_manager_secret.shared_config.secret_id
}

output "vpc_id" {
  description = "The VPC network ID (if created)"
  value       = var.create_vpc ? google_compute_network.vpc[0].id : null
}

output "subnet_id" {
  description = "The subnet ID (if created)"
  value       = var.create_vpc ? google_compute_subnetwork.subnet[0].id : null
}

output "enabled_apis" {
  description = "List of enabled Google APIs"
  value       = keys(google_project_service.required_apis)
}