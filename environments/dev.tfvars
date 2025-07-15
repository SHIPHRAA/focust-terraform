# Development environment configuration

# Common variables
project_id             = "focust-dev"
region                 = "us-central1"
environment            = "dev"
terraform_state_bucket = "focust-dev-terraform-state"

# Base infrastructure
project_name         = "focust"
create_vpc           = false
asset_retention_days = 7

# Frontend configuration
frontend_image_tag       = "dev-latest"
frontend_port            = 3000
frontend_cpu_limit       = "0.5"
frontend_memory_limit    = "256Mi"
frontend_min_instances   = 0
frontend_max_instances   = 10
frontend_custom_domain   = ""
frontend_cors_origins    = ["http://localhost:3000", "http://localhost:3001"]

# Backend configuration
backend_image_tag        = "dev-latest"
backend_port             = 8080
backend_cpu_limit        = "1"
backend_memory_limit     = "512Mi"
backend_min_instances    = 0
backend_max_instances    = 10
backend_allowed_members  = ["allUsers"]
data_retention_days      = 30

# Database configuration (backend)
create_database             = true
database_tier               = "db-f1-micro"
database_availability_type  = "ZONAL"
database_disk_size          = 10
database_max_connections    = "50"

# Auth configuration
auth_image_tag         = "dev-latest"
auth_port              = 8080
auth_cpu_limit         = "0.5"
auth_memory_limit      = "256Mi"
auth_min_instances     = 0
auth_max_instances     = 10
jwt_expiry             = "1h"
refresh_token_expiry   = "7d"
session_duration       = "3600"
allowed_origins        = ["http://localhost:3000", "http://localhost:3001"]
auth_providers         = ["email", "google"]

# Cross-service URLs (will be populated after deployment)
backend_url   = ""
auth_url      = ""
frontend_urls = ["http://localhost:3000"]