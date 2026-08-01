##############################################################################
# Per-service availability SLOs, tagged by service_name.
#
# Measures the same signal as the "High Error Rate" golden-signal alert in
# alerts.tf (non-error trace spans / total trace spans over resource.service.name),
# expressed as a rolling-window SLO with fastburn/slowburn alerting instead
# of a fixed threshold. This intentionally reuses the existing traceql
# expression style rather than inventing a separate Prometheus metric that
# doesn't exist for these services.
##############################################################################

resource "grafana_slo" "aci_service" {
  for_each = toset(var.aci_services)

  name        = "${each.value} — Availability"
  description = "Rolling-window availability SLO for ${each.value}, derived from the same non-error/total trace span ratio used by the High Error Rate golden-signal alert."
  folder_uid  = grafana_folder.aci.uid

  query {
    type = "grafana_queries"

    grafana_queries {
      grafana_queries = jsonencode([
        {
          datasource = {
            type = "tempo"
            uid  = var.tempo_datasource_uid
          }
          refId     = "Success"
          queryType = "traceql"
          query     = "{resource.service.name=\"${each.value}\" && status!=error} | rate()"
        },
        {
          datasource = {
            type = "tempo"
            uid  = var.tempo_datasource_uid
          }
          refId     = "Total"
          queryType = "traceql"
          query     = "{resource.service.name=\"${each.value}\"} | rate()"
        },
        {
          datasource = {
            type = "__expr__"
            uid  = "__expr__"
          }
          refId      = "Expression"
          type       = "math"
          expression = "$Success / $Total"
        }
      ])
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
