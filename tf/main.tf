terraform {
  backend "gcs" {
    bucket = "your-terraform-state-bucket"
    prefix = "mongodb-replica-set"
  }

   required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "google" {
  project     = "my-project-id"
  region      = "us-central1"
  credintials = "./gcp-project-infra/keys.json"
}

