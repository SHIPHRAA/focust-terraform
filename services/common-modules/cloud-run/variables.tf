# Required variables
variable "service_name" {
  description = "The name of the Cloud Run service"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

# Container configuration
variable "container_image" {
  description = "Full container image path. If empty, will use artifact_registry_url/service_name:image_tag"
  type        = string
  default     = ""
}

variable "artifact_registry_url" {
  description = "The Artifact Registry URL (used if container_image is not provided)"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "The container image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "The port the container listens on"
  type        = number
  default     = 8080
}

# Environment variables
variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret environment variables"
  type = map(object({
    secret_name = string
    secret_key  = string
  }))
  default = {}
}

# Resource limits
variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

# Scaling configuration
variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 100
}

variable "container_concurrency" {
  description = "Maximum number of concurrent requests per container"
  type        = number
  default     = 80
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

# Service account
variable "service_account_email" {
  description = "Service account email. If empty, a new one will be created"
  type        = string
  default     = ""
}

variable "service_account_roles" {
  description = "Roles to grant to the service account (if created)"
  type        = set(string)
  default = [
    "roles/storage.objectViewer",
    "roles/secretmanager.secretAccessor"
  ]
}

# Access control
variable "allowed_members" {
  description = "List of members allowed to invoke the service"
  type        = list(string)
  default     = ["allUsers"]
}

# VPC configuration
variable "vpc_connector" {
  description = "VPC connector name for private IP access"
  type        = string
  default     = ""
}

variable "vpc_egress" {
  description = "VPC egress setting (all-traffic or private-ranges-only)"
  type        = string
  default     = "private-ranges-only"
}

# Storage bucket
variable "create_storage_bucket" {
  description = "Whether to create a storage bucket for the service"
  type        = bool
  default     = false
}

variable "bucket_retention_days" {
  description = "Number of days to retain objects in the bucket"
  type        = number
  default     = 30
}

variable "enable_cors" {
  description = "Whether to enable CORS on the bucket"
  type        = bool
  default     = false
}

variable "cors_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

# Secrets configuration
variable "create_config_secret" {
  description = "Whether to create a configuration secret"
  type        = bool
  default     = false
}

variable "config_secret_data" {
  description = "Additional data to store in the configuration secret"
  type        = map(any)
  default     = {}
}

# Optional features
variable "create_artifact_repo" {
  description = "Whether to create a service-specific Artifact Registry repository"
  type        = bool
  default     = false
}

variable "custom_domain" {
  description = "Custom domain for the Cloud Run service"
  type        = string
  default     = ""
}