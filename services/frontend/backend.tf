terraform {
  backend "gcs" {
    bucket = "focust-dev-terraform-state"
    prefix = "frontend-service/terraform/state"
  }
}