# Auth service configuration

# Data source to read base infrastructure outputs
data "terraform_remote_state" "base" {
  backend = "gcs"
  config = {
    bucket = var.terraform_state_bucket
    prefix = "focust-infra-state"
  }
}

# Use the Cloud Run module for auth service
module "auth" {
  source = "../common-modules/cloud-run"

  # Basic configuration
  service_name = "focust-auth"
  region       = var.region
  project_id   = var.project_id
  environment  = var.environment

  # Container configuration
  artifact_registry_url = data.terraform_remote_state.base.outputs.artifact_registry_url
  image_tag             = var.auth_image_tag
  container_port        = var.auth_port

  # Environment variables
  env_vars = {
    NODE_ENV           = var.environment
    PORT               = tostring(var.auth_port)
    JWT_EXPIRY         = var.jwt_expiry
    REFRESH_EXPIRY     = var.refresh_token_expiry
    SESSION_DURATION   = var.session_duration
    ALLOWED_ORIGINS    = join(",", var.allowed_origins)
  }

  # Secret environment variables
  secret_env_vars = merge(
    {
      JWT_SECRET = {
        secret_name = google_secret_manager_secret.jwt_secret.secret_id
        secret_key  = "latest"
      }
    },
    var.auth_secret_env_vars
  )

  # Resource limits
  cpu_limit    = var.auth_cpu_limit
  memory_limit = var.auth_memory_limit

  # Scaling configuration
  min_instances         = var.auth_min_instances
  max_instances         = var.auth_max_instances
  container_concurrency = var.auth_concurrency
  timeout_seconds       = var.auth_timeout_seconds

  # Access control - auth service is public for login endpoints
  allowed_members = ["allUsers"]

  # Service account with additional permissions
  service_account_roles = [
    "roles/storage.objectViewer",
    "roles/secretmanager.secretAccessor",
    "roles/firebaseauth.admin",
    "roles/identityplatform.admin"
  ]

  # Configuration secret
  create_config_secret = true
  config_secret_data = {
    frontend_urls = var.frontend_urls
    backend_url   = var.backend_url
    auth_providers = var.auth_providers
  }

  # VPC configuration (if using private services)
  vpc_connector = var.vpc_connector
  vpc_egress    = var.vpc_egress
}

# Create JWT secret
resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "${var.environment}-jwt-secret"
  project   = var.project_id

  replication {
    auto {}
  }
}

# Generate and store JWT secret value
resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "google_secret_manager_secret_version" "jwt_secret" {
  secret      = google_secret_manager_secret.jwt_secret.id
  secret_data = random_password.jwt_secret.result
}

# Grant auth service access to JWT secret
resource "google_secret_manager_secret_iam_member" "auth_jwt_access" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.jwt_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.auth.service_account_email}"
}