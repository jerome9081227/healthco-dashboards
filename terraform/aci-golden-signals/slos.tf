##############################################################################
# Per-service availability SLOs, tagged by service_name.
#
# NOTE: Grafana Cloud SLOs are metric-based, not trace-based. An earlier
# version of this file tried to build the query from the same Tempo/traceql
# expressions used in alerts.tf via the `grafana_queries` type, but the SLO
# API rejects Tempo outright: "datasource type 'tempo' is not valid for
# GrafanaQueries type" (this isn't documented anywhere -- found by hitting
# the live API). So this uses the `ratio` query type instead, which takes
# plain PromQL success/total metric strings -- the same approach the
# provider's own docs use, and the same convention already used by the
# pre-existing terraform/slos/aiserviceserror_rate.tf SLO in this repo
# (http_requests_total, labeled by service).
#
# This assumes an http_requests_total-style counter exists per service. If
# these ACI demo services don't actually emit that exact metric/label, the
# SLO will still validate and create fine (the API only checks query syntax
# and datasource type at creation, not that matching data exists) -- it'll
# just show no data until the real metric name is confirmed and swapped in.
##############################################################################

resource "grafana_slo" "aci_service" {
  for_each = toset(var.aci_services)

  name        = "${each.value} — Availability"
  description = "Rolling-window availability SLO for ${each.value}, based on the proportion of non-5xx HTTP requests."
  folder_uid  = grafana_folder.aci.uid

  query {
    type = "ratio"

    ratio {
      success_metric  = "http_requests_total{service=\"${each.value}\", status!~\"5..\"}"
      total_metric    = "http_requests_total{service=\"${each.value}\"}"
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

##############################################################################
# Standalone SLO for "api-gateway" -- NOTE: this is a distinct service_name
# from "aci-gateway" (already covered above via var.aci_services). Kept as
# its own resource rather than folded into the for_each loop since
# "api-gateway" isn't part of that service list.
##############################################################################

resource "grafana_slo" "api_gateway" {
  name        = "api-gateway — Availability"
  description = "Rolling-window availability SLO for api-gateway, based on the proportion of non-5xx HTTP requests."
  folder_uid  = grafana_folder.aci.uid

  query {
    type = "ratio"

    ratio {
      success_metric  = "http_requests_total{service=\"api-gateway\", status!~\"5..\"}"
      total_metric    = "http_requests_total{service=\"api-gateway\"}"
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
    value = "api-gateway"
  }

  label {
    key   = "team"
    value = "aci"
  }

  alerting {
    fastburn {
      annotation {
        key   = "summary"
        value = "api-gateway SLO fast burn -- error budget depleting rapidly"
      }
      label {
        key   = "severity"
        value = "critical"
      }
    }

    slowburn {
      annotation {
        key   = "summary"
        value = "api-gateway SLO slow burn -- error budget trending down"
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

output "api_gateway_slo_id" {
  description = "SLO ID for api-gateway -- open in Grafana Cloud SLO app to view burn-rate dashboard"
  value       = grafana_slo.api_gateway.id
}
