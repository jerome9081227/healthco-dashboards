variable "grafana_url" {
  type = string
}

variable "grafana_auth" {
  type      = string
  sensitive = true
}

variable "tempo_datasource_uid" {
  description = "UID of the Tempo datasource backing ACI trace data"
  type        = string
  default     = "grafanacloud-traces"
}

variable "aci_services" {
  description = "ACI services to build golden-signal dashboards/alerts for"
  type        = list(string)
  default = [
    "aci-loadgen",
    "aci-storefront",
    "aci-ledger",
    "aci-gateway",
    "aci-accounts",
    "aci-fraud",
    "aci-payments",
  ]
}

variable "error_rate_threshold_reqps" {
  description = "Error spans/sec threshold that fires the High Error Rate alert"
  type        = number
  default     = 0.5
}

variable "latency_p95_threshold_ns" {
  description = "p95 duration (nanoseconds) threshold that fires the High Latency alert"
  type        = number
  default     = 500000000
}

variable "traffic_drop_threshold_reqps" {
  description = "Below this request rate the service is considered silent/down"
  type        = number
  default     = 0.01
}

variable "notification_contact_point" {
  description = "Contact point name to notify (must already exist in Grafana)"
  type        = string
  default     = "grafana-default-email"
}

##############################################################################
# Synthetic Monitoring
##############################################################################

variable "sm_url" {
  description = "Synthetic Monitoring API URL (from SM plugin Config tab)"
  type        = string
  default     = "https://synthetic-monitoring-api.grafana.net"
}

variable "sm_access_token" {
  description = "Synthetic Monitoring access token (from SM plugin Config tab)"
  type        = string
  sensitive   = true
}

variable "sm_probes" {
  description = "Public probe IDs/locations to run the aci-storefront check from"
  type        = list(string)
  default     = ["London", "New York"]
}

# Only aci-storefront is reachable via a public hostname. The other 6 services
# resolve to *.internal.*.azurecontainerapps.io hostnames that public SM
# probes cannot reach -- they need a private probe deployed inside that
# VNet before a check can be added for them. See synthetics.tf for details.
variable "aci_public_targets" {
  description = "Public HTTPS target URL per ACI service that has a publicly reachable hostname"
  type        = map(string)
  default = {
    "aci-storefront" = "https://aci-storefront.salmondesert-baa25d35.eastus.azurecontainerapps.io/"
  }
}

##############################################################################
# Grafana IRM / OnCall
##############################################################################

variable "oncall_url" {
  description = "Grafana OnCall API URL for this stack"
  type        = string
  default     = "https://oncall-prod-us-central-0.grafana.net/oncall"
}

