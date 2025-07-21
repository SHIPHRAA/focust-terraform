terraform {
  backend "gcs" {
    bucket = "focust-dev-terraform-state"
    prefix = "base/terraform/state"
  }
}