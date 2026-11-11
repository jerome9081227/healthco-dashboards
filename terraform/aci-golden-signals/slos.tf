##############################################################################
# Per-service availability SLOs, tagged by service_name.
#
# Built on traces_spanmetrics_calls_total{service, status_code} -- Tempo's
# metrics-generator span metrics, auto-written into the grafanacloud-prom
# Prometheus/Mimir datasource from the same trace data alerts.tf queries
# directly via Tempo/traceql. Confirmed live against the actual stack
# (jeromewwallace.grafana.net) rather than assumed:
#
#   curl .../api/v1/label/__name__/values --data-urlencode 'match[]={service="aci-gateway"}'
#     -> traces_spanmetrics_calls_total, _latency_bucket, _latency_count,
#        _latency_sum, _size_total
#   curl .../api/v1/series --data-urlencode 'match[]=traces_spanmetrics_calls_total{service="aci-gateway"}'
#     -> status_code label with values STATUS_CODE_OK / STATUS_CODE_ERROR
#
# Two earlier versions of this file were wrong: one tried to query Tempo
# directly via the `grafana_queries` type, which the SLO API rejects
# outright ("datasource type 'tempo' is not valid for GrafanaQueries
# type"); the other used a plausible-sounding but nonexistent
# http_requests_total metric, matching the pre-existing (also unverified)
# terraform/slos/aiserviceserror_rate.tf convention. This version uses the
# `ratio` query type (which the SLO API does accept) against a metric
# confirmed to actually exist on this stack.
#
# NOTE (2026-08-02): the `alerting` block (fastburn/slowburn) is
# deliberately omitted here. The org's alert_rule quota was sitting at
# 999-1000/1000, and the SLO app provisions its burn-rate recording rules
# and its fastburn/slowburn alerts as one bundled rule group -- when the
# quota blocked that group from being created ("alert rule not created:
# Grafana query error: (HTTP 403 ...): quota has been exceeded"), the SLO
# showed an Error status AND had no burn-rate data at all, not just missing
# alerts. Dropping alerting lets the SLO's own rule group (and therefore its
# data) get created without needing a new alert-rule slot. Re-add the
# alerting block once the quota is freed up or raised.
##############################################################################

resource "grafana_slo" "aci_service" {
  for_each = toset(var.aci_services)

  name        = "${each.value} — Availability"
  description = "Rolling-window availability SLO for ${each.value}, based on the proportion of non-error spans (traces_spanmetrics_calls_total)."
  folder_uid  = grafana_folder.aci.uid

  query {
    type = "ratio"

    ratio {
      success_metric  = "traces_spanmetrics_calls_total{service=\"${each.value}\", status_code=\"STATUS_CODE_OK\"}"
      total_metric    = "traces_spanmetrics_calls_total{service=\"${each.value}\"}"
      group_by_labels = ["service"]
    }
  }

  objectives {
    value  = var.slo_objective
    window = "30d"
  }

  destination_datasource {
    uid = var.slo_destination_datasource_uid
  }

  label {
    key   = "service_name"
    value = each.value
  }

  label {
    key   = "team"
    value = "aci"
  }
}

output "aci_service_slos" {
  description = "SLO IDs per ACI service -- open in Grafana Cloud SLO app to view burn-rate dashboards"
  value       = { for k, v in grafana_slo.aci_service : k => v.id }
}
