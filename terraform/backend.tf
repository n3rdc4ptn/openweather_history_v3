terraform {
  backend "gcs" {
    bucket = "gha-terraform-state"
    prefix = "terraform/state"
  }
}
