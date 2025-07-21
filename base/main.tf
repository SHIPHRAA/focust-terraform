# Enable required APIs for all services
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com"
  ])

  project = var.project_id
  service = each.key

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create shared Artifact Registry repository
resource "google_artifact_registry_repository" "shared_repo" {
  repository_id = "focust-services"
  location      = var.region
  format        = "DOCKER"
  description   = "Shared repository for all focust microservices"

  depends_on = [google_project_service.required_apis["artifactregistry.googleapis.com"]]
}

# Create shared VPC (optional - for future use)
resource "google_compute_network" "vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id

  depends_on = [google_project_service.required_apis["compute.googleapis.com"]]
}

# Create shared subnet (optional - for future use with private services)
resource "google_compute_subnetwork" "subnet" {
  count         = var.create_vpc ? 1 : 0
  name          = "${var.project_name}-subnet-${var.region}"
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc[0].id
  project       = var.project_id

  private_ip_google_access = true
}

# Shared service account for infrastructure operations
resource "google_service_account" "infrastructure_sa" {
  account_id   = "${var.project_name}-infrastructure"
  display_name = "Infrastructure Service Account"
  description  = "Service account for infrastructure operations"
  project      = var.project_id
}

# Grant necessary permissions to infrastructure service account
resource "google_project_iam_member" "infrastructure_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/run.admin",
    "roles/storage.admin",
    "roles/secretmanager.admin",
    "roles/iam.serviceAccountUser"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.infrastructure_sa.email}"
}

# Create shared storage bucket for assets
resource "google_storage_bucket" "shared_assets" {
  name                        = "${var.project_id}-shared-assets"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true
  project                     = var.project_id

  lifecycle_rule {
    condition {
      age = var.asset_retention_days
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Create shared secrets for cross-service communication
resource "google_secret_manager_secret" "shared_config" {
  secret_id = "${var.project_name}-shared-config"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis["secretmanager.googleapis.com"]]
}

# Store shared configuration
resource "google_secret_manager_secret_version" "shared_config" {
  secret = google_secret_manager_secret.shared_config.id
  secret_data = jsonencode({
    environment           = var.environment
    project_id            = var.project_id
    region                = var.region
    artifact_registry_url = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.shared_repo.repository_id}"
    shared_assets_bucket  = google_storage_bucket.shared_assets.name
  })
}

# VPC and networking (conditional creation)
resource "google_compute_network" "vpc" {
  count                   = var.create_vpc ? 1 : 0
  name                    = "${var.project_name}-vpc-${var.environment}"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  count         = var.create_vpc ? 1 : 0
  name          = "${var.project_name}-subnet-${var.environment}"
  project       = var.project_id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc[0].id

  # Enable private Google access
  private_ip_google_access = true
}

# VPC Connector for Cloud Run to access private resources
resource "google_vpc_access_connector" "connector" {
  count         = var.create_vpc ? 1 : 0
  name          = "${var.project_name}-connector-${var.environment}"
  project       = var.project_id
  region        = var.region
  ip_cidr_range = "10.0.1.0/28"
  network       = google_compute_network.vpc[0].id
}

# Enable required APIs for VPC
resource "google_project_service" "vpc_apis" {
  for_each = var.create_vpc ? toset([
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com"
  ]) : []
  
  project = var.project_id
  service = each.value

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  count         = var.create_vpc ? 1 : 0
  name          = "${var.project_name}-private-ip-${var.environment}"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc[0].id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count                   = var.create_vpc ? 1 : 0
  network                 = google_compute_network.vpc[0].id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}