# Auth service configuration

# Enable SQL Admin API for database management
resource "google_project_service" "sqladmin" {
  count   = var.create_database ? 1 : 0
  project = data.terraform_remote_state.base.outputs.project_id
  service = "sqladmin.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Data source to read base infrastructure outputs
data "terraform_remote_state" "base" {
  backend = "gcs"
  config = {
    bucket = var.terraform_state_bucket
    prefix = "base/terraform/state"
  }
}

# Use the Cloud Run module for auth service
module "auth" {
  source = "../common-modules/cloud-run"

  # Basic configuration
  service_name = "focust-auth"
  region       = data.terraform_remote_state.base.outputs.region
  project_id   = data.terraform_remote_state.base.outputs.project_id
  environment  = data.terraform_remote_state.base.outputs.environment

  # Container configuration
  artifact_registry_url = data.terraform_remote_state.base.outputs.artifact_registry_url
  container_image       = "${data.terraform_remote_state.base.outputs.artifact_registry_url}/focust-auth-service:${var.auth_image_tag}"
  image_tag             = var.auth_image_tag
  container_port        = var.auth_port

  # Environment variables
  env_vars = {
    NODE_ENV           = data.terraform_remote_state.base.outputs.environment
    PORT               = tostring(var.auth_port)
    JWT_EXPIRY         = var.jwt_expiry
    REFRESH_EXPIRY     = var.refresh_token_expiry
    SESSION_DURATION   = var.session_duration
    ALLOWED_ORIGINS    = join(",", var.allowed_origins)
  }

  # Secret environment variables
  secret_env_vars = local.auth_secret_env_vars

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
    frontend_urls = jsonencode(var.frontend_urls)
    backend_url   = var.backend_url
    auth_providers = jsonencode(var.auth_providers)
  }

  # VPC configuration (if using private services)
  vpc_connector = var.vpc_connector
  vpc_egress    = var.vpc_egress
}

# Create JWT secret
resource "google_secret_manager_secret" "jwt_secret" {
  secret_id = "${data.terraform_remote_state.base.outputs.environment}-jwt-secret"
  project   = data.terraform_remote_state.base.outputs.project_id

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
  project   = data.terraform_remote_state.base.outputs.project_id
  secret_id = google_secret_manager_secret.jwt_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.auth.service_account_email}"
}

# Create Cloud SQL instance for auth database (PostgreSQL)
resource "google_sql_database_instance" "auth_db" {
  count            = var.create_database ? 1 : 0
  name             = "focust-auth-db-${data.terraform_remote_state.base.outputs.environment}"
  database_version = var.database_version # POSTGRES_13 by default
  region           = data.terraform_remote_state.base.outputs.region
  project          = data.terraform_remote_state.base.outputs.project_id

  settings {
    tier              = var.database_tier
    availability_type = var.database_availability_type
    disk_size         = var.database_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = data.terraform_remote_state.base.outputs.region
      point_in_time_recovery_enabled = data.terraform_remote_state.base.outputs.environment == "production"
      transaction_log_retention_days = data.terraform_remote_state.base.outputs.environment == "production" ? 7 : 1
      backup_retention_settings {
        retained_backups = data.terraform_remote_state.base.outputs.environment == "production" ? 30 : 7
        retention_unit   = "COUNT"
      }
    }

    database_flags {
      name  = "max_connections"
      value = var.database_max_connections
    }

    ip_configuration {
      ipv4_enabled    = true
      
      # Allow Cloud Run access (will be restricted in production)
      dynamic "authorized_networks" {
        for_each = data.terraform_remote_state.base.outputs.environment != "production" ? [1] : []
        content {
          name  = "allow-all-dev"
          value = "0.0.0.0/0"
        }
      }
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }
  }

  deletion_protection = data.terraform_remote_state.base.outputs.environment == "production"

  depends_on = [google_project_service.sqladmin]
}

# Create auth database
resource "google_sql_database" "auth_db" {
  count    = var.create_database ? 1 : 0
  name     = var.database_name
  instance = google_sql_database_instance.auth_db[0].name
  project  = data.terraform_remote_state.base.outputs.project_id
}

# Create database user
resource "google_sql_user" "auth_user" {
  count    = var.create_database ? 1 : 0
  name     = var.database_user
  instance = google_sql_database_instance.auth_db[0].name
  password = random_password.auth_database_password[0].result
  project  = data.terraform_remote_state.base.outputs.project_id
}

# Generate secure database password
resource "random_password" "auth_database_password" {
  count   = var.create_database ? 1 : 0
  length  = 32
  special = true
}

# Store database URL in Secret Manager
resource "google_secret_manager_secret" "auth_database_url" {
  count     = var.create_database ? 1 : 0
  secret_id = "focust-auth-database-url-${data.terraform_remote_state.base.outputs.environment}"
  project   = data.terraform_remote_state.base.outputs.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "auth_database_url" {
  count  = var.create_database ? 1 : 0
  secret = google_secret_manager_secret.auth_database_url[0].id
  secret_data = format(
    "postgresql://%s:%s@%s:5432/%s?sslmode=require",
    google_sql_user.auth_user[0].name,
    google_sql_user.auth_user[0].password,
    google_sql_database_instance.auth_db[0].public_ip_address,
    google_sql_database.auth_db[0].name
  )
}

# Grant auth service account access to database secret
resource "google_secret_manager_secret_iam_member" "auth_database_access" {
  count     = var.create_database ? 1 : 0
  project   = data.terraform_remote_state.base.outputs.project_id
  secret_id = google_secret_manager_secret.auth_database_url[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.auth.service_account_email}"
}

# Update auth module to use database secret
locals {
  auth_secret_env_vars = var.create_database ? merge(
    {
      JWT_SECRET = {
        secret_name = google_secret_manager_secret.jwt_secret.secret_id
        secret_key  = "latest"
      }
      DATABASE_URL = {
        secret_name = google_secret_manager_secret.auth_database_url[0].secret_id
        secret_key  = "latest"
      }
    },
    var.auth_secret_env_vars
  ) : merge(
    {
      JWT_SECRET = {
        secret_name = google_secret_manager_secret.jwt_secret.secret_id
        secret_key  = "latest"
      }
    },
    var.auth_secret_env_vars
  )
}