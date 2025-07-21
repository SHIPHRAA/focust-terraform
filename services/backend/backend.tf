terraform {
  backend "gcs" {
    bucket = "focust-dev-terraform-state"
    prefix = "backend-service/terraform/state"
  }
}