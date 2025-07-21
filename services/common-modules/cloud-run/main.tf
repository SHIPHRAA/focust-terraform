# Cloud Run service module - reusable for all microservices

# Create service-specific Artifact Registry repository (optional)
resource "google_artifact_registry_repository" "service_repo" {
  count         = var.create_artifact_repo ? 1 : 0
  repository_id = "${var.service_name}-repo"
  location      = var.region
  format        = "DOCKER"
  description   = "Repository for ${var.service_name} container images"
}

# Create Cloud Run service
resource "google_cloud_run_service" "service" {
  name     = "${var.service_name}-${var.environment}"
  location = var.region

  template {
    spec {
      containers {
        image = var.container_image != "" ? var.container_image : "${var.artifact_registry_url}/${var.service_name}:${var.image_tag}"
        
        ports {
          container_port = var.container_port
        }

        # Dynamic environment variables
        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        # Dynamic secret environment variables
        dynamic "env" {
          for_each = var.secret_env_vars
          content {
            name = env.key
            value_from {
              secret_key_ref {
                name = env.value.secret_name
                key  = env.value.secret_key
              }
            }
          }
        }

        # Resource limits
        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }
      }

      # Service account
      service_account_name = var.service_account_email != "" ? var.service_account_email : google_service_account.service_account[0].email

      # Scaling configuration
      container_concurrency = var.container_concurrency
      timeout_seconds       = var.timeout_seconds
    }

    metadata {
      annotations = merge(
        {
          "autoscaling.knative.dev/minScale" = tostring(var.min_instances)
          "autoscaling.knative.dev/maxScale" = tostring(var.max_instances)
          "run.googleapis.com/client-name"   = "terraform"
        },
        var.vpc_connector != "" ? {
          "run.googleapis.com/vpc-access-connector" = var.vpc_connector
          "run.googleapis.com/vpc-access-egress"     = var.vpc_egress
        } : {}
      )
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Create service account if not provided
resource "google_service_account" "service_account" {
  count        = var.service_account_email == "" ? 1 : 0
  account_id   = var.service_name
  display_name = "Cloud Run ${var.service_name}"
  description  = "Service account for Cloud Run ${var.service_name} service"
}

# Grant necessary permissions to service account
resource "google_project_iam_member" "service_account_roles" {
  for_each = var.service_account_email == "" ? var.service_account_roles : toset([])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.service_account[0].email}"
}

# IAM policy for Cloud Run service
resource "google_cloud_run_service_iam_member" "invoker" {
  for_each = toset(var.allowed_members)
  
  service  = google_cloud_run_service.service.name
  location = google_cloud_run_service.service.location
  role     = "roles/run.invoker"
  member   = each.value
}

# Create service-specific storage bucket if needed
resource "google_storage_bucket" "service_bucket" {
  count                       = var.create_storage_bucket ? 1 : 0
  name                        = "${var.project_id}-${var.service_name}-${var.environment}"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = var.bucket_retention_days
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }

  dynamic "cors" {
    for_each = var.enable_cors ? [1] : []
    content {
      origin          = var.cors_origins
      method          = var.cors_methods
      response_header = ["*"]
      max_age_seconds = 3600
    }
  }
}

# Grant service account access to bucket
resource "google_storage_bucket_iam_member" "bucket_access" {
  count  = var.create_storage_bucket ? 1 : 0
  bucket = google_storage_bucket.service_bucket[0].name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account_email != "" ? var.service_account_email : google_service_account.service_account[0].email}"
}

# Create service-specific secrets
resource "google_secret_manager_secret" "service_config" {
  count     = var.create_config_secret ? 1 : 0
  secret_id = "${var.service_name}-config-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }
}

# Store service configuration
resource "google_secret_manager_secret_version" "service_config" {
  count  = var.create_config_secret ? 1 : 0
  secret = google_secret_manager_secret.service_config[0].id
  secret_data = jsonencode(merge(
    {
      environment   = var.environment
      service_name  = var.service_name
      cloud_run_url = google_cloud_run_service.service.status[0].url
    },
    var.create_storage_bucket ? {
      bucket_name = google_storage_bucket.service_bucket[0].name
    } : {},
    var.config_secret_data
  ))
}

# Grant service account access to secrets
resource "google_secret_manager_secret_iam_member" "secret_access" {
  count     = var.create_config_secret ? 1 : 0
  project   = var.project_id
  secret_id = google_secret_manager_secret.service_config[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.service_account_email != "" ? var.service_account_email : google_service_account.service_account[0].email}"
}

# Domain mapping (optional)
resource "google_cloud_run_domain_mapping" "domain" {
  count    = var.custom_domain != "" ? 1 : 0
  name     = var.custom_domain
  location = var.region

  spec {
    route_name = google_cloud_run_service.service.name
  }
}