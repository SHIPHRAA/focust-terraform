# Staging environment configuration

# Common variables
project_id             = "focust-stage"
region                 = "us-central1"
environment            = "staging"
terraform_state_bucket = "focust-stage-terraform-state"

# Base infrastructure
project_name         = "focust"
create_vpc           = false
asset_retention_days = 30

# Frontend configuration
frontend_image_tag       = "stage-latest"
frontend_port            = 3000
frontend_cpu_limit       = "1"
frontend_memory_limit    = "512Mi"
frontend_min_instances   = 1
frontend_max_instances   = 50
frontend_custom_domain   = "staging.focust.app"
frontend_cors_origins    = ["https://staging.focust.app"]

# Backend configuration
backend_image_tag        = "stage-latest"
backend_port             = 8080
backend_cpu_limit        = "2"
backend_memory_limit     = "1Gi"
backend_min_instances    = 1
backend_max_instances    = 50
backend_allowed_members  = ["allUsers"]
data_retention_days      = 60

# Database configuration (backend)
create_database             = true
database_tier               = "db-g1-small"
database_availability_type  = "ZONAL"
database_disk_size          = 20
database_max_connections    = "100"

# Auth configuration
auth_image_tag         = "stage-latest"
auth_port              = 8080
auth_cpu_limit         = "1"
auth_memory_limit      = "512Mi"
auth_min_instances     = 1
auth_max_instances     = 25
jwt_expiry             = "1h"
refresh_token_expiry   = "7d"
session_duration       = "3600"
allowed_origins        = ["https://staging.focust.app"]
auth_providers         = ["email", "google"]

# Cross-service URLs (will be populated after deployment)
backend_url   = ""
auth_url      = ""
frontend_urls = ["https://staging.focust.app"]