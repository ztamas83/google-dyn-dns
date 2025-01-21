variable "function_name" {
  description = "A user-defined name of the function."
  type        = string
  default     = "example-managed-by-terraform"
}

variable "location" {
  description = "The location of this cloud function."
  type        = string
  default     = "europe-north1"
}

variable "description" {
  description = "User-provided description of a function."
  type        = string
  default     = "Cloud function example managed by Terraform"
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

variable "runtime" {
  description = "The runtime in which to run the function. Required when deploying a new function, optional when updating an existing function."
  type        = string
  default     = "python39"
}

variable "entry_point" {
  description = "The name of the function (as defined in source code) that will be executed. Defaults to the resource name suffix, if not specified. For backward compatibility, if function with given name is not found, then the system will try to use function named \"function\". For Node.js this is name of a function exported by the module specified in source_location."
  type        = string
  default     = "main"
}

variable "min_instance_count" {
  description = "(Optional) The limit on the minimum number of function instances that may coexist at a given time."
  type        = number
  default     = 1
}

variable "max_instance_count" {
  description = "(Optional) The limit on the maximum number of function instances that may coexist at a given time."
  type        = number
  default     = 10
}

variable "timeout_seconds" {
  description = "(Optional) The function execution timeout. Execution is considered failed and can be terminated if the function is not completed at the end of the timeout period. Defaults to 60 seconds."
  type        = number
  default     = 60
}

variable "ingress_settings" {
  description = "(Optional) Available ingress settings. Defaults to \"ALLOW_ALL\" if unspecified. Default value is ALLOW_ALL. Possible values are ALLOW_ALL, ALLOW_INTERNAL_ONLY, and ALLOW_INTERNAL_AND_GCLB."
  type        = string
  default     = "ALLOW_ALL"
}

variable "all_traffic_on_latest_revision" {
  description = "(Optional) Whether 100% of traffic is routed to the latest revision. Defaults to true."
  type        = bool
  default     = true
}

variable "bucket_location" {
  description = "The bucket location where the cloud function code will be stored"
  type        = string
  default     = "EUROPE-NORTH1"
}

variable "excludes" {
  description = "Files to exclude from the cloud function src directory"
  type        = list(string)
  default     = [
    "README.md"
  ]
}

variable "dns_zone_name" {
    description = "The hosted zone name"
    type        = string
}

variable "domain_name" {
    description = "The DNS domain name in the zone"
    type        = string
}

variable "api_user" {
    description = "The API user"
    type        = string
    default = "pfsense"
}

variable "api_key_secret" {
    description = "The API key secret name"
    type        = string
    default = "apiKey"
}