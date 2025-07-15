# Backend service configuration

variable "create_database" {
  description = "Whether to create the backend Cloud SQL database and related resources"
  type        = bool
  default     = false
}

variable "database_version" {
  description = "The version of the Cloud SQL database (e.g., POSTGRES_13, MYSQL_8_0)"
  type        = string
}

variable "database_availability_type" {
  description = "The availability type for the Cloud SQL instance (e.g., ZONAL, REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "database_tier" {
  description = "The machine type (tier) for the Cloud SQL instance (e.g., db-f1-micro, db-g1-small, db-custom-1-3840)"
  type        = string
}

variable "database_max_connections" {
  description = "The maximum number of database connections for the Cloud SQL instance"
  type        = number
  default     = 100
}

variable "database_disk_size" {
  description = "The disk size (in GB) for the Cloud SQL instance"
  type        = number
  default     = 10
}

variable "database_name" {
  description = "The name of the backend database to create"
  type        = string
}

variable "database_user" {
  description = "The username for the backend database user"
  type        = string
}

variable "vpc_network_id" {
  description = "The ID of the VPC network to use for private IP configuration"
  type        = string
}

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
  }

  # Secret environment variables
  secret_env_vars = local.backend_secret_env_vars

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

# Create Cloud SQL instance for backend database
resource "google_sql_database_instance" "backend_db" {
  count            = var.create_database ? 1 : 0
  name             = "focust-backend-db-${var.environment}"
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier              = var.database_tier
    availability_type = var.database_availability_type
    disk_size         = var.database_disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      location                       = var.region
      point_in_time_recovery_enabled = var.environment == "production"
      transaction_log_retention_days = var.environment == "production" ? 7 : 1
      backup_retention_settings {
        retained_backups = var.environment == "production" ? 30 : 7
        retention_unit   = "COUNT"
      }
    }

    database_flags {
      name  = "max_connections"
      value = var.database_max_connections
    }

    ip_configuration {
      ipv4_enabled    = true
      private_network = var.vpc_network_id
      
      # Allow Cloud Run access (will be restricted in production)
      dynamic "authorized_networks" {
        for_each = var.environment != "production" ? [1] : []
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

  deletion_protection = var.environment == "production"
}

# Create database
resource "google_sql_database" "backend_db" {
  count    = var.create_database ? 1 : 0
  name     = var.database_name
  instance = google_sql_database_instance.backend_db[0].name
  project  = var.project_id
}

# Create database user
resource "google_sql_user" "backend_user" {
  count    = var.create_database ? 1 : 0
  name     = var.database_user
  instance = google_sql_database_instance.backend_db[0].name
  password = random_password.database_password[0].result
  project  = var.project_id
}

# Generate secure database password
resource "random_password" "database_password" {
  count   = var.create_database ? 1 : 0
  length  = 32
  special = true
}

# Store database URL in Secret Manager
resource "google_secret_manager_secret" "database_url" {
  count     = var.create_database ? 1 : 0
  secret_id = "focust-backend-database-url-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "database_url" {
  count  = var.create_database ? 1 : 0
  secret = google_secret_manager_secret.database_url[0].id
  secret_data = format(
    "postgresql://%s:%s@%s:5432/%s?sslmode=require",
    google_sql_user.backend_user[0].name,
    google_sql_user.backend_user[0].password,
    google_sql_database_instance.backend_db[0].public_ip_address,
    google_sql_database.backend_db[0].name
  )
}

# Grant backend service account access to database secret
resource "google_secret_manager_secret_iam_member" "backend_database_access" {
  count     = var.create_database ? 1 : 0
  project   = var.project_id
  secret_id = google_secret_manager_secret.database_url[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${module.backend.service_account_email}"
}

# Update backend module to use database secret
locals {
  backend_secret_env_vars = var.create_database ? merge(
    {
      DATABASE_URL = {
        secret_name = google_secret_manager_secret.database_url[0].secret_id
        secret_key  = "latest"
      }
    },
    var.backend_secret_env_vars
  ) : var.backend_secret_env_vars
}