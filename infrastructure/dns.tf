
resource "google_dns_managed_zone" "dns_zone" {
  name        = replace(var.domain_name, ".", "-")
  dns_name    = "${var.domain_name}."
  description = "${var.domain_name} managed zone"
  labels = {
    service_name = local.service_name
  }
  visibility = "public"
}