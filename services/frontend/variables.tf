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

# Frontend specific variables
variable "frontend_image_tag" {
  description = "The frontend container image tag"
  type        = string
  default     = "latest"
}

variable "frontend_port" {
  description = "The port the frontend container listens on"
  type        = number
  default     = 3000
}

# Resource limits
variable "frontend_cpu_limit" {
  description = "CPU limit for frontend container"
  type        = string
  default     = "1"
}

variable "frontend_memory_limit" {
  description = "Memory limit for frontend container"
  type        = string
  default     = "512Mi"
}

# Scaling
variable "frontend_min_instances" {
  description = "Minimum number of frontend instances"
  type        = number
  default     = 1
}

variable "frontend_max_instances" {
  description = "Maximum number of frontend instances"
  type        = number
  default     = 100
}

variable "frontend_concurrency" {
  description = "Maximum concurrent requests per frontend instance"
  type        = number
  default     = 80
}

variable "frontend_timeout_seconds" {
  description = "Request timeout for frontend"
  type        = number
  default     = 300
}

# Storage
variable "asset_retention_days" {
  description = "Number of days to retain frontend assets"
  type        = number
  default     = 30
}

# CORS
variable "frontend_cors_origins" {
  description = "CORS allowed origins for frontend"
  type        = list(string)
  default     = ["*"]
}

# Service URLs
variable "backend_url" {
  description = "The backend service URL"
  type        = string
  default     = ""
}

variable "auth_url" {
  description = "The auth service URL"
  type        = string
  default     = ""
}

# Custom domain
variable "frontend_custom_domain" {
  description = "Custom domain for frontend service"
  type        = string
  default     = ""
}