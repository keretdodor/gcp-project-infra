terraform {
  backend "gcs" {
    bucket = "wideops-project-bucket"
    prefix = "mongodb-replica-set"
  }

   required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }

     random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  

  required_version = ">= 1.0.0"
}

resource "random_integer" "int" {
  min = 100
  max = 1000000
}

provider "google" {
  project     = "gcp-mongoxnodeapp-project"
  region      = var.region
}

module "common" {
  source = "./modules/common"

  region = var.region
  machine_type = "e2-medium"

}

module "mongodb" {
  source = "./modules/mongodb"

  region         = var.region
  machine_type   = "e2-medium"
  bastion_prv_ip = module.common.bastion_prv_ip
  bastion_pub_ip = module.common.bastion_pub_ip
  private_subnet = module.common.private_subnet_name
  vpc_name       = module.common.vpc_name
  nat_router_id  = module.common.nat_router_id

}