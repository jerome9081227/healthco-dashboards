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

  alerting {
    fastburn {
      annotation {
        key   = "summary"
        value = "${each.value} SLO fast burn -- error budget depleting rapidly"
      }
      label {
        key   = "severity"
        value = "critical"
      }
    }

    slowburn {
      annotation {
        key   = "summary"
        value = "${each.value} SLO slow burn -- error budget trending down"
      }
      label {
        key   = "severity"
        value = "warning"
      }
    }
  }
}

output "aci_service_slos" {
  description = "SLO IDs per ACI service -- open in Grafana Cloud SLO app to view burn-rate dashboards"
  value       = { for k, v in grafana_slo.aci_service : k => v.id }
}
