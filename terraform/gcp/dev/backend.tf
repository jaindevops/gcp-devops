terraform {
  backend "gcs" {
    bucket = "terraform-bucket-gcp-devops"
    prefix = "terraform/gcp-devops/state"
  }
}