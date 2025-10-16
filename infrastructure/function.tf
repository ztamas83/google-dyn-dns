
resource "google_storage_bucket_object" "source" {
  name   = "${local.function_name}/${data.archive_file.this.output_sha}.zip"
  bucket = google_storage_bucket.source_bucket.id
  source = data.archive_file.this.output_path
}

resource "google_cloudfunctions2_function" "function" {
  name        = local.function_name
  location    = var.location
  description = "Dyn-DNS updater"
  labels = {
    service_name = local.service_name
  }

  build_config {
    runtime     = "nodejs22"
    entry_point = "httpFunction"

    source {
      storage_source {
        bucket = google_storage_bucket.source_bucket.id
        object = google_storage_bucket_object.source.name
      }
    }
  }

  service_config {
    min_instance_count = 0
    max_instance_count = 1
    timeout_seconds    = 180

    environment_variables = {
      DNS_ZONE   = google_dns_managed_zone.dns_zone.name
      DNS_DOMAIN = var.domain_name
    }
    secret_environment_variables {
      key        = "API_PASSWORD"
      secret     = "DNS_API_PASSWORD"
      version    = "latest"
      project_id = var.project
    }

    secret_environment_variables {
      key        = "API_USER"
      secret     = "DNS_API_USER"
      version    = "latest"
      project_id = var.project
    }


    ingress_settings               = "ALLOW_ALL"
    all_traffic_on_latest_revision = "true"
    service_account_email          = google_service_account.function_runtime_account.email
  }
}

resource "google_cloud_run_service_iam_binding" "public_binding" {
  project    = google_cloudfunctions2_function.function.project
  location   = google_cloudfunctions2_function.function.location
  service    = google_cloudfunctions2_function.function.name
  role       = "roles/run.invoker"
  members    = ["allUsers"]
  depends_on = [google_cloudfunctions2_function.function]
  lifecycle {
    replace_triggered_by = [google_cloudfunctions2_function.function]
  }
}

data "archive_file" "this" {
  type        = "zip"
  output_path = "/tmp/${local.function_name}.zip"
  source_dir  = "${path.module}/../dns-updater-ts/dist"
  excludes    = var.excludes
}