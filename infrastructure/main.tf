data "google_project" "current" {}


resource "google_storage_bucket" "source_bucket" {
  name                        = "${var.project}-gcf-sources"
  project                     = var.project
  location                    = var.location
  force_destroy               = true
  uniform_bucket_level_access = true
  storage_class               = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 2
    }
    action {
      type = "Delete"
    }
  }
}