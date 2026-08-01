resource "grafana_dashboard" "aci_golden_signals" {
  folder = grafana_folder.aci.id
  config_json = jsonencode({
    title         = "ACI Services — Golden Signals"
    description   = "Traffic, error rate, and latency (p50/p95/p99) for Azure Container Instance services, derived from Tempo trace data. No infrastructure metrics (CPU/memory) are available for these services."
    schemaVersion = 39
    editable      = true
    tags          = ["aci", "golden-signals", "tempo"]
    time = {
      from = "now-24h"
      to   = "now"
    }
    refresh  = "5m"
    timezone = "browser"

    templating = {
      list = [
        {
          name       = "service"
          type       = "custom"
          label      = "ACI Service"
          query      = join(",", var.aci_services)
          current    = { text = var.aci_services[0], value = var.aci_services[0] }
          options    = [for s in var.aci_services : { text = s, value = s }]
          multi      = false
          includeAll = false
        }
      ]
    }

    panels = [
      {
        id      = 1
        title   = "About this dashboard"
        type    = "text"
        gridPos = { x = 0, y = 0, w = 24, h = 3 }
        options = {
          mode    = "markdown"
          content = "**ACI Services — Golden Signals.** Traffic, errors, and latency for Azure Container Instance services, derived entirely from Tempo trace data (`resource.service.name`). No CPU/memory metrics exist for these services, so saturation is not shown. Select a service above."
        }
      },
      {
        id          = 2
        title       = "Request Rate ($service)"
        type        = "timeseries"
        gridPos     = { x = 0, y = 3, w = 8, h = 8 }
        fieldConfig = { defaults = { unit = "reqps" } }
        targets = [{
          refId      = "A"
          datasource = { type = "tempo", uid = var.tempo_datasource_uid }
          queryType  = "traceql"
          query      = "{resource.service.name=\"$service\"} | rate()"
        }]
      },
      {
        id          = 3
        title       = "Error Rate ($service)"
        type        = "timeseries"
        gridPos     = { x = 8, y = 3, w = 8, h = 8 }
        fieldConfig = { defaults = { unit = "reqps", color = { mode = "fixed", fixedColor = "red" } } }
        targets = [{
          refId      = "A"
          datasource = { type = "tempo", uid = var.tempo_datasource_uid }
          queryType  = "traceql"
          query      = "{resource.service.name=\"$service\" && status=error} | rate()"
        }]
      },
      {
        id          = 4
        title       = "Latency p50/p95/p99 ($service)"
        type        = "timeseries"
        gridPos     = { x = 16, y = 3, w = 8, h = 8 }
        fieldConfig = { defaults = { unit = "ns" } }
        targets = [{
          refId      = "A"
          datasource = { type = "tempo", uid = var.tempo_datasource_uid }
          queryType  = "traceql"
          query      = "{resource.service.name=\"$service\"} | quantile_over_time(duration, 0.5, 0.95, 0.99)"
        }]
      },
      {
        id      = 5
        title   = "Current Error Rate ($service)"
        type    = "stat"
        gridPos = { x = 0, y = 11, w = 6, h = 6 }
        fieldConfig = {
          defaults = {
            unit  = "reqps"
            min   = 0
            color = { mode = "fixed", fixedColor = "red" }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green", value = null },
                { color = "orange", value = 0.1 },
                { color = "red", value = 1 },
              ]
            }
          }
        }
        options = { reduceOptions = { calcs = ["lastNotNull"] } }
        targets = [{
          refId      = "A"
          datasource = { type = "tempo", uid = var.tempo_datasource_uid }
          queryType  = "traceql"
          query      = "{resource.service.name=\"$service\" && status=error} | rate()"
        }]
      },
      {
        id          = 6
        title       = "Request Rate by Route ($service)"
        type        = "timeseries"
        gridPos     = { x = 6, y = 11, w = 9, h = 6 }
        fieldConfig = { defaults = { unit = "reqps" } }
        targets = [{
          refId      = "A"
          datasource = { type = "tempo", uid = var.tempo_datasource_uid }
          queryType  = "traceql"
          query      = "{resource.service.name=\"$service\"} | rate() by (span.http.route)"
        }]
      },
      {
        id          = 7
        title       = "Request Rate by Status Code ($service)"
        type        = "timeseries"
        gridPos     = { x = 15, y = 11, w = 9, h = 6 }
        fieldConfig = { defaults = { unit = "reqps" } }
        targets = [{
          refId      = "A"
          datasource = { type = "tempo", uid = var.tempo_datasource_uid }
          queryType  = "traceql"
          query      = "{resource.service.name=\"$service\"} | rate() by (span.http.status_code)"
        }]
      },
    ]
  })
}
