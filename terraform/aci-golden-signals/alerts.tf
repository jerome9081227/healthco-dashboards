resource "grafana_rule_group" "aci_golden_signals" {
  for_each = toset(var.aci_services)

  name             = "ACI Golden Signals — ${each.value}"
  folder_uid       = grafana_folder.aci.uid
  interval_seconds = 60

  rule {
    name      = "${each.value} — High Error Rate"
    condition = "C"
    for       = "5m"

    data {
      ref_id         = "A"
      datasource_uid = var.tempo_datasource_uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        queryType = "traceql"
        query     = "{resource.service.name=\"${each.value}\" && status=error} | rate()"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        type       = "reduce"
        expression = "A"
        reducer    = "last"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        type       = "threshold"
        expression = "B"
        conditions = [{
          evaluator = { type = "gt", params = [var.error_rate_threshold_reqps] }
        }]
      })
    }

    annotations = {
      summary = "${each.value} error span rate exceeded ${var.error_rate_threshold_reqps} req/s"
    }
    labels = {
      service = each.value
      signal  = "errors"
      team    = "aci"
    }
    notification_settings {
      contact_point = var.notification_contact_point
    }
  }

  rule {
    name      = "${each.value} — High Latency p95"
    condition = "C"
    for       = "5m"

    data {
      ref_id         = "A"
      datasource_uid = var.tempo_datasource_uid
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        queryType = "traceql"
        query     = "{resource.service.name=\"${each.value}\"} | quantile_over_time(duration, 0.95)"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        type       = "reduce"
        expression = "A"
        reducer    = "last"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 600
        to   = 0
      }
      model = jsonencode({
        type       = "threshold"
        expression = "B"
        conditions = [{
          evaluator = { type = "gt", params = [var.latency_p95_threshold_ns] }
        }]
      })
    }

    annotations = {
      summary = "${each.value} p95 latency exceeded ${var.latency_p95_threshold_ns / 1000000}ms"
    }
    labels = {
      service_name = each.value
      signal       = "latency"
      team         = "aci"
    }
    notification_settings {
      contact_point = var.notification_contact_point
    }
  }

  rule {
    name      = "${each.value} — Traffic Drop"
    condition = "C"
    for       = "10m"

    data {
      ref_id         = "A"
      datasource_uid = var.tempo_datasource_uid
      relative_time_range {
        from = 900
        to   = 0
      }
      model = jsonencode({
        queryType = "traceql"
        query     = "{resource.service.name=\"${each.value}\"} | rate()"
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 900
        to   = 0
      }
      model = jsonencode({
        type       = "reduce"
        expression = "A"
        reducer    = "last"
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 900
        to   = 0
      }
      model = jsonencode({
        type       = "threshold"
        expression = "B"
        conditions = [{
          evaluator = { type = "lt", params = [var.traffic_drop_threshold_reqps] }
        }]
      })
    }

    annotations = {
      summary = "${each.value} request rate dropped near zero — possible outage"
    }
    labels = {
      service  = each.value
      signal   = "traffic"
      team     = "aci"
      severity = "critical"
    }
    notification_settings {
      contact_point = var.notification_contact_point
    }
  }
}
