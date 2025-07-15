terraform {
  backend "gcs" {
    prefix = "backend-service/terraform/state"
  }
}