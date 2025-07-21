terraform {
  backend "gcs" {
    bucket = "focust-dev-terraform-state"
    prefix = "auth-service/terraform/state"
  }
}