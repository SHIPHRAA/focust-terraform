terraform {
  backend "gcs" {
    prefix = "focust-infra-state"
  }
}