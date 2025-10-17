resource "google_service_account" "a38_dnsupdater_account" {
  account_id   = "a38-updater"
  display_name = "DNS updaterservice account"
}

resource "google_service_account" "function_runtime_account" {
  account_id   = "${local.function_name}-runtime"
  display_name = "Function runtime service account"
}

resource "google_project_iam_custom_role" "dns_record_updater" {
  role_id     = "dnsRecordUpdater"
  title       = "DNS record Updater role"
  description = "Allows to update a DNS record"
  permissions = ["dns.managedZones.list",
    "dns.managedZones.get",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
    "dns.resourceRecordSets.create",
    "dns.changes.create",
    "secretmanager.versions.access"
  ]
}

resource "google_project_iam_member" "function_dnsupdater_binding" {
  project = var.project
  role    = google_project_iam_custom_role.dns_record_updater.id
  member  = google_service_account.function_runtime_account.member
}

