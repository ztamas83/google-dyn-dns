data "google_project" "current" {}

resource "google_cloudfunctions2_function" "function" {
  name        = var.function_name
  location    = var.location
  description = var.description
  labels      = var.labels

  build_config {
    runtime     = var.runtime
    entry_point = var.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.this.id
        object = google_storage_bucket_object.this.name
      }
    }
  }

  service_config {
    min_instance_count  = 0
    max_instance_count  = 1
    timeout_seconds                = var.timeout_seconds
    environment_variables          = {
      dnsZoneName = var.dns_zone_name
      dnsDomain = var.domain_name
      authPassword = "projects/${data.google_project.current.project_id}/secrets/apiKey:1"
    }
    ingress_settings               = var.ingress_settings
    all_traffic_on_latest_revision = var.all_traffic_on_latest_revision
    service_account_email = google_service_account.function_runtime_account.email
  }
}

resource "google_cloud_run_service_iam_binding" "public_binding" {
  project = google_cloudfunctions2_function.function.project
  location = google_cloudfunctions2_function.function.location
  service = google_cloudfunctions2_function.function.name
  role = "roles/run.invoker"
  members = ["allUsers"]
  depends_on = [ google_cloudfunctions2_function.function ]
  lifecycle {
    replace_triggered_by = [ google_cloudfunctions2_function.function ]
  }
}

data "archive_file" "this" {
  type        = "zip"
  output_path = "/tmp/${var.function_name}.zip"
  source_dir  = "${path.module}/../dns-updater"
  excludes    = var.excludes
}

resource "google_storage_bucket" "this" {
  name = "${var.project}-gcf-source"
  project = var.project
  location = var.bucket_location
  force_destroy = true
  uniform_bucket_level_access = true
  storage_class = "STANDARD"
  
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

resource "google_storage_bucket_object" "this" {
  name   = "${var.function_name}.${data.archive_file.this.output_sha}.zip"
  bucket = google_storage_bucket.this.id
  source = data.archive_file.this.output_path
}