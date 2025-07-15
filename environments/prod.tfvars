# Production environment configuration

# Common variables
project_id             = "focust-prod"
region                 = "us-central1"
environment            = "production"
terraform_state_bucket = "focust-prod-terraform-state"

# Base infrastructure
project_name         = "focust"
create_vpc           = true  # Enable VPC for production
subnet_cidr          = "10.0.0.0/24"
asset_retention_days = 90

# Frontend configuration
frontend_image_tag       = "v1.0.0"  # Use specific version tags in production
frontend_port            = 3000
frontend_cpu_limit       = "2"
frontend_memory_limit    = "1Gi"
frontend_min_instances   = 2
frontend_max_instances   = 100
frontend_custom_domain   = "focust.app"
frontend_cors_origins    = ["https://focust.app", "https://www.focust.app"]

# Backend configuration
backend_image_tag        = "v1.0.0"  # Use specific version tags in production
backend_port             = 8080
backend_cpu_limit        = "4"
backend_memory_limit     = "2Gi"
backend_min_instances    = 2
backend_max_instances    = 100
backend_allowed_members  = ["allUsers"]
database_url             = ""  # Set via environment or secret
data_retention_days      = 365
vpc_connector            = ""  # Will be set if using VPC

# Auth configuration
auth_image_tag         = "v1.0.0"  # Use specific version tags in production
auth_port              = 8080
auth_cpu_limit         = "2"
auth_memory_limit      = "1Gi"
auth_min_instances     = 2
auth_max_instances     = 50
jwt_expiry             = "30m"
refresh_token_expiry   = "30d"
session_duration       = "1800"
allowed_origins        = ["https://focust.app", "https://www.focust.app"]
auth_providers         = ["email", "google", "github"]
vpc_connector          = ""  # Will be set if using VPC

# Cross-service URLs (will be populated after deployment)
backend_url   = ""
auth_url      = ""
frontend_urls = ["https://focust.app", "https://www.focust.app"]