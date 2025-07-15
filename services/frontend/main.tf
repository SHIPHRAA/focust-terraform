# Frontend service configuration

# Data source to read base infrastructure outputs
data "terraform_remote_state" "base" {
  backend = "gcs"
  config = {
    bucket = var.terraform_state_bucket
    prefix = "focust-infra-state"
  }
}

# Use the Cloud Run module for frontend service
module "frontend" {
  source = "../common-modules/cloud-run"

  # Basic configuration
  service_name = "focust-frontend"
  region       = var.region
  project_id   = var.project_id
  environment  = var.environment

  # Container configuration
  artifact_registry_url = data.terraform_remote_state.base.outputs.artifact_registry_url
  image_tag             = var.frontend_image_tag
  container_port        = var.frontend_port

  # Environment variables
  env_vars = {
    NODE_ENV = var.environment
    PORT     = tostring(var.frontend_port)
  }

  # Resource limits
  cpu_limit    = var.frontend_cpu_limit
  memory_limit = var.frontend_memory_limit

  # Scaling configuration
  min_instances         = var.frontend_min_instances
  max_instances         = var.frontend_max_instances
  container_concurrency = var.frontend_concurrency
  timeout_seconds       = var.frontend_timeout_seconds

  # Access control - frontend is public
  allowed_members = ["allUsers"]

  # Storage for frontend assets
  create_storage_bucket = true
  bucket_retention_days = var.asset_retention_days
  enable_cors           = true
  cors_origins          = var.frontend_cors_origins

  # Configuration secret
  create_config_secret = true
  config_secret_data = {
    api_base_url = var.backend_url
    auth_url     = var.auth_url
  }

  # Custom domain
  custom_domain = var.frontend_custom_domain
}