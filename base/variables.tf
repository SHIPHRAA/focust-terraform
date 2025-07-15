variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "project_name" {
  description = "The name of the project (used for resource naming)"
  type        = string
  default     = "focust"
}

variable "environment" {
  description = "The deployment environment (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "create_vpc" {
  description = "Whether to create a VPC network"
  type        = bool
  default     = false
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "asset_retention_days" {
  description = "Number of days to retain assets in storage bucket"
  type        = number
  default     = 30
}