variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "terraform_state_bucket" {
  description = "The GCS bucket for Terraform state"
  type        = string
}

# Auth specific variables
variable "auth_image_tag" {
  description = "The auth container image tag"
  type        = string
  default     = "latest"
}

variable "auth_port" {
  description = "The port the auth container listens on"
  type        = number
  default     = 8080
}

# Resource limits
variable "auth_cpu_limit" {
  description = "CPU limit for auth container"
  type        = string
  default     = "1"
}

variable "auth_memory_limit" {
  description = "Memory limit for auth container"
  type        = string
  default     = "512Mi"
}

# Scaling
variable "auth_min_instances" {
  description = "Minimum number of auth instances"
  type        = number
  default     = 1
}

variable "auth_max_instances" {
  description = "Maximum number of auth instances"
  type        = number
  default     = 50
}

variable "auth_concurrency" {
  description = "Maximum concurrent requests per auth instance"
  type        = number
  default     = 100
}

variable "auth_timeout_seconds" {
  description = "Request timeout for auth"
  type        = number
  default     = 300
}

# Auth configuration
variable "jwt_expiry" {
  description = "JWT token expiry time"
  type        = string
  default     = "1h"
}

variable "refresh_token_expiry" {
  description = "Refresh token expiry time"
  type        = string
  default     = "7d"
}

variable "session_duration" {
  description = "Session duration in seconds"
  type        = string
  default     = "3600"
}

variable "allowed_origins" {
  description = "Allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "auth_providers" {
  description = "Enabled authentication providers"
  type        = list(string)
  default     = ["email", "google"]
}

# Service URLs
variable "frontend_urls" {
  description = "List of frontend URLs for redirects"
  type        = list(string)
  default     = []
}

variable "backend_url" {
  description = "The backend service URL"
  type        = string
  default     = ""
}

# Secrets
variable "auth_secret_env_vars" {
  description = "Secret environment variables for auth"
  type = map(object({
    secret_name = string
    secret_key  = string
  }))
  default = {}
}

# VPC
variable "vpc_connector" {
  description = "VPC connector for private access"
  type        = string
  default     = ""
}

variable "vpc_egress" {
  description = "VPC egress setting"
  type        = string
  default     = "private-ranges-only"
}