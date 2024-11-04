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
  region      = var.region
  credintials = "./gcp-project/keys.json"
}

