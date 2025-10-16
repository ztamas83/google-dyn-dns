locals {
  service_name  = "dyn-dns"
  function_name = "${local.service_name}-updater"
}

variable "location" {
  description = "The location of this cloud function."
  type        = string
  default     = "europe-north1"
}

variable "project" {
  description = "The ID of the project in which the resource belongs."
  type        = string
}

variable "labels" {
  description = "A set of key/value label pairs associated with this Cloud Function."
  type        = map(string)
  default     = {}
}

variable "excludes" {
  description = "Files to exclude from the cloud function src directory"
  type        = list(string)
  default = [
    "README.md"
  ]
}

variable "domain_name" {
  description = "The DNS domain name in the zone"
  type        = string
}