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

# Backend specific variables
variable "backend_image_tag" {
  description = "The backend container image tag"
  type        = string
  default     = "latest"
}

variable "backend_port" {
  description = "The port the backend container listens on"
  type        = number
  default     = 8080
}

# Resource limits
variable "backend_cpu_limit" {
  description = "CPU limit for backend container"
  type        = string
  default     = "2"
}

variable "backend_memory_limit" {
  description = "Memory limit for backend container"
  type        = string
  default     = "1Gi"
}

# Scaling
variable "backend_min_instances" {
  description = "Minimum number of backend instances"
  type        = number
  default     = 1
}

variable "backend_max_instances" {
  description = "Maximum number of backend instances"
  type        = number
  default     = 100
}

variable "backend_concurrency" {
  description = "Maximum concurrent requests per backend instance"
  type        = number
  default     = 100
}

variable "backend_timeout_seconds" {
  description = "Request timeout for backend"
  type        = number
  default     = 300
}

# Access control
variable "backend_allowed_members" {
  description = "Members allowed to invoke the backend service"
  type        = list(string)
  default     = ["allUsers"]
}

# Storage
variable "data_retention_days" {
  description = "Number of days to retain backend data"
  type        = number
  default     = 90
}

# Database configuration
variable "create_database" {
  description = "Whether to create a Cloud SQL database"
  type        = bool
  default     = true
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_availability_type" {
  description = "Database availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "database_disk_size" {
  description = "Database disk size in GB"
  type        = number
  default     = 10
}

variable "database_max_connections" {
  description = "Maximum number of database connections"
  type        = string
  default     = "100"
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "focust"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "focust_user"
}

variable "vpc_network_id" {
  description = "VPC network ID for private database access"
  type        = string
  default     = ""
}

# Service URLs
variable "auth_url" {
  description = "The auth service URL"
  type        = string
  default     = ""
}

variable "frontend_urls" {
  description = "List of allowed frontend URLs for CORS"
  type        = list(string)
  default     = []
}

# Secrets
variable "backend_secret_env_vars" {
  description = "Secret environment variables for backend"
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