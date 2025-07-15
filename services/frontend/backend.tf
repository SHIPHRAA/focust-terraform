terraform {
  backend "gcs" {
    prefix = "frontend-service/terraform/state"
  }
}