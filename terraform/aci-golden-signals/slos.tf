##############################################################################
# ⚠️ NOT YET FUNCTIONAL — see README note below.
#
# Availability SLOs (99.9% over rolling 28d) for the 7 ACI services.
#
# grafana_slo's "ratio" query type requires Prometheus-compatible metrics
# (success_metric / total_metric are PromQL selectors evaluated against
# destination_datasource). As of this writing, none of the ACI services
# (aci-loadgen, aci-storefront, aci-ledger, aci-gateway, aci-accounts,
# aci-fraud, aci-payments) emit Prometheus metrics — they only produce
# Tempo trace data.
#
# These SLOs are written against the metric names Tempo's metrics-generator
# span-metrics processor WOULD emit if enabled
# (traces_spanmetrics_calls_total{service="...", status_code="..."}).
# They will show "no data" / fail to evaluate until:
#   1. Tempo's metrics-generator span-metrics processor is enabled and
#      configured to write into var.prometheus_datasource_uid, AND
#   2. The `service` label dimension on traces_spanmetrics_calls_total
#      matches each service name below (adjust if your metrics-generator
#      uses a different dimension name, e.g. "service_name").
#
# Once span metrics are flowing, verify the exact metric/label names in
# Grafana (Explore -> your Prometheus datasource -> search
# "traces_spanmetrics") and adjust success_metric/total_metric/group_by_labels
# accordingly.
##############################################################################

variable "prometheus_datasource_uid" {
  description = "Prometheus-compatible datasource UID that will receive Tempo span metrics (metrics-generator remote_write target)"
  type        = string
  default     = "grafanacloud-prom"
}

resource "grafana_slo" "aci_availability" {
  for_each = toset(var.aci_services)

  name        = "${each.value} — Availability"
  description = "99.9% of ${each.value} requests are not errors, based on Tempo span metrics (requires metrics-generator span-metrics processor to be enabled — see file header)."

  query {
    type = "ratio"
    ratio {
      success_metric  = "traces_spanmetrics_calls_total{service=\"${each.value}\", status_code!=\"STATUS_CODE_ERROR\"}"
      total_metric    = "traces_spanmetrics_calls_total{service=\"${each.value}\"}"
      group_by_labels = ["service"]
    }
  }

  objectives {
    value  = 0.999
    window = "28d"
  }

  destination_datasource {
    uid = var.prometheus_datasource_uid
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
        key   = "name"
        value = "${each.value} SLO Burn Rate Very High"
      }
      annotation {
        key   = "description"
        value = "${each.value} error budget is burning too fast"
      }
    }
    slowburn {
      annotation {
        key   = "name"
        value = "${each.value} SLO Burn Rate High"
      }
      annotation {
        key   = "description"
        value = "${each.value} error budget is burning faster than expected"
      }
    }
  }
}

output "aci_slo_ids" {
  value = { for k, v in grafana_slo.aci_availability : k => v.id }
}
