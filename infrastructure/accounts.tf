resource "google_service_account" "function_runtime_account" {
  account_id   = "${var.function_name}-runtime"
  display_name = "Function runtime service account"
}

resource "google_project_iam_custom_role" "dns_record_updater" {
    role_id = "dnsRecordUpdater"
    title = "DNS record Updater role"
    description = "Allows to update a DNS record"
    permissions = ["dns.managedZones.list", 
        "dns.managedZones.get",
        "dns.resourceRecordSets.get",
        "dns.resourceRecordSets.list",
        "dns.resourceRecordSets.update",
        "secretmanager.versions.access"
    ]
}

resource "google_project_iam_member" "function_dnsupdater_binding" {
  project = var.project
  role    = google_project_iam_custom_role.dns_record_updater.id
  member = google_service_account.function_runtime_account.member
}

