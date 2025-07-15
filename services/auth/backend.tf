terraform {
  backend "gcs" {
    prefix = "auth-service/terraform/state"
  }
}