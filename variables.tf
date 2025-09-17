variable "rg_location" {
  type        = string
  default     = "uksouth"
  description = "jbrg location"
}

variable "sa_location" {
  type        = string
  default     = "uksouth"
  description = "stjb location"
}

variable "jbondcloudrg_name" {
  type    = string
  default = "jbondcloudrg"
}

variable "jbcloud_sa_name" {
  type    = string
  default = "stjbondcloud"
}

variable "dns_zone_jbond_dev" {
  type = string
}

variable "function_app_name" {
  type = string
}

variable "cosmos_account_name" {
  type = string
}

variable "cosmos_db_name" {
  type = string
}

variable "cosmos_container_name" {
  type = string
}

variable "swa_name" {
  type        = string
  description = "Static Web App name"
}

variable "root_domain" {
  type        = string
  description = "Root domain (e.g. jbond.dev)"
}

variable "www_label" {
  type        = string
  description = "WWW label"
  default     = "www"
}

variable "swa_location" {
    type = string
}