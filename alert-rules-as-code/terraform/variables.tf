# ---------------------------------------------------------------------------
# Alert Rules as Code — Variable Definitions
# ---------------------------------------------------------------------------
# The service map IS your coverage registry.
# length(var.services) == covered service count, always.
# ---------------------------------------------------------------------------

variable "grafana_url" {
  description = "Your Grafana Cloud instance URL, e.g. https://yourorg.grafana.net"
  type        = string
}

variable "grafana_auth" {
  description = "Service account token with alerting write permissions"
  type        = string
  sensitive   = true
}

variable "datasource_uid" {
  description = <<-EOT
    UID of the Prometheus/Mimir datasource used in alert queries.
    Defaults to 'grafana-testdata-datasource' so the demo runs
    out of the box without real metrics. Swap for your Mimir UID
    once you have real instrumentation.
  EOT
  type    = string
  default = "grafana-testdata-datasource"
}

# ---------------------------------------------------------------------------
# Service registry
# ---------------------------------------------------------------------------
# Add/remove entries here to add/remove all four golden signal alert rules.
# This is the single source of truth for coverage.
# ---------------------------------------------------------------------------

variable "services" {
  description = "Service registry — one entry per service, four alert rules created per entry"
  type = map(object({
    alliance           = string        # logical grouping (Payments, Fulfillment, …)
    tier               = string        # "1" = customer-critical, "2" = internal
    latency_threshold  = number        # p99 latency in seconds
    error_threshold    = number        # error rate as a decimal (0.05 = 5%)
    saturation_threshold = number      # capacity utilization (0.85 = 85%)
    oncall_team        = string        # IRM contact point name
    runbook_base_url   = string        # base URL; signal name appended automatically
  }))
}
