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
