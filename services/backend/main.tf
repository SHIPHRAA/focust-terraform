# Backend service configuration

# Data source to read base infrastructure outputs
data "terraform_remote_state" "base" {
  backend = "gcs"
  config = {
    bucket = var.terraform_state_bucket
    prefix = "focust-infra-state"
  }
}

# Use the Cloud Run module for backend service
module "backend" {
  source = "../common-modules/cloud-run"

  # Basic configuration
  service_name = "focust-backend"
  region       = var.region
  project_id   = var.project_id
  environment  = var.environment

  # Container configuration
  artifact_registry_url = data.terraform_remote_state.base.outputs.artifact_registry_url
  image_tag             = var.backend_image_tag
  container_port        = var.backend_port

  # Environment variables
  env_vars = {
    NODE_ENV    = var.environment
    PORT        = tostring(var.backend_port)
    AUTH_URL    = var.auth_url
    DATABASE_URL = var.database_url
  }

  # Secret environment variables
  secret_env_vars = var.backend_secret_env_vars

  # Resource limits
  cpu_limit    = var.backend_cpu_limit
  memory_limit = var.backend_memory_limit

  # Scaling configuration
  min_instances         = var.backend_min_instances
  max_instances         = var.backend_max_instances
  container_concurrency = var.backend_concurrency
  timeout_seconds       = var.backend_timeout_seconds

  # Access control - backend requires authentication
  allowed_members = var.backend_allowed_members

  # Service account with additional permissions
  service_account_roles = [
    "roles/storage.objectViewer",
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.client",
    "roles/datastore.user"
  ]

  # Storage for backend data
  create_storage_bucket = true
  bucket_retention_days = var.data_retention_days

  # Configuration secret
  create_config_secret = true
  config_secret_data = {
    auth_url      = var.auth_url
    frontend_urls = var.frontend_urls
  }

  # VPC configuration (if using private services)
  vpc_connector = var.vpc_connector
  vpc_egress    = var.vpc_egress
}