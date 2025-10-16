terraform {
  backend "gcs" {
    
  }

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.7.1"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 7.6.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.location
}
  