terraform {
  backend "gcs" {
    bucket = "b31-domain-terraform-states"
    prefix = "b31-domain"
  }

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 5.33.0"
    }
  }
}

provider "google" {
    project = var.project
    region = var.location
}
  