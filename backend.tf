# Terraform backend configuration for state management
# This file should be placed in each module directory (base, services/frontend, etc.)
# and configured with the appropriate state path

terraform {
  backend "gcs" {
    # The bucket name should be set via -backend-config or environment variable
    # bucket = "your-terraform-state-bucket"
    
    # Use different prefixes for each module to maintain separate state files
    # Base infrastructure: prefix = "focust-infra-state"
    # Frontend service: prefix = "terraform/state/services/frontend"
    # Backend service: prefix = "terraform/state/services/backend"
    # Auth service: prefix = "terraform/state/services/auth"
  }
}