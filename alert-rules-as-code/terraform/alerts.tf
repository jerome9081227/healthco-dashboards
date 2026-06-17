# ---------------------------------------------------------------------------
# Alert Rules as Code — Golden Signal rules, one group per service
# ---------------------------------------------------------------------------
#
# for_each over var.services creates four alert rules per service:
#   latency / traffic (absent) / errors / saturation
#
# To add coverage for a new service: add it to terraform.tfvars and run
# terraform apply. To remove: delete the entry and run terraform apply.
# No Grafana UI interaction required.
#
# Datasource note:
#   Default uses grafana-testdata-datasource so the demo runs without real
#   metrics. Each "data" block references a TestData scenario that generates
#   synthetic time-series; the threshold expressions evaluate against it.
#   Swap datasource_uid + PromQL expressions for Mimir in production.
# ---------------------------------------------------------------------------

resource "grafana_rule_group" "golden_signals" {
  for_each = var.services

  name             = "${each.key}-golden-signals"
  folder_uid       = grafana_folder.alliance[each.value.alliance].uid
  interval_seconds = 60

  # ── LATENCY ──────────────────────────────────────────────────────────────
  rule {
    name      = "${each.key}-latency-p99"
    condition = "threshold"
    for       = "5m"

    annotations = {
      service   = each.key
      alliance  = each.value.alliance
      signal    = "latency"
      tier      = each.value.tier
      runbook   = "${each.value.runbook_base_url}/latency"
      summary   = "${each.key} p99 latency exceeds ${each.value.latency_threshold}s"
    }
    labels = {
      severity = each.value.tier == "1" ? "critical" : "warning"
      team     = each.value.oncall_team
    }

    data {
      ref_id         = "metrics"
      datasource_uid = var.datasource_uid
      relative_time_range { from = 300; to = 0 }
      model = jsonencode({
        refId      = "metrics"
        scenarioId = "random_walk"
        alias      = "p99_latency"
        # Production swap → expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket{service="${each.key}",env="prod"}[5m]))
      })
    }

    data {
      ref_id         = "threshold"
      datasource_uid = "__expr__"
      relative_time_range { from = 300; to = 0 }
      model = jsonencode({
        refId      = "threshold"
        type       = "threshold"
        datasource = { type = "__expr__", uid = "__expr__" }
        conditions = [{
          evaluator = { params = [each.value.latency_threshold], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["metrics"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  # ── TRAFFIC (absent) ─────────────────────────────────────────────────────
  rule {
    name      = "${each.key}-traffic-absent"
    condition = "threshold"
    for       = "5m"

    annotations = {
      service   = each.key
      alliance  = each.value.alliance
      signal    = "traffic"
      tier      = each.value.tier
      runbook   = "${each.value.runbook_base_url}/traffic"
      summary   = "${each.key} receiving zero traffic — service may be down or misconfigured"
    }
    labels = {
      severity = "critical"
      team     = each.value.oncall_team
    }

    data {
      ref_id         = "metrics"
      datasource_uid = var.datasource_uid
      relative_time_range { from = 300; to = 0 }
      model = jsonencode({
        refId      = "metrics"
        scenarioId = "random_walk"
        alias      = "request_rate"
        # Production swap → expr: rate(http_requests_total{service="${each.key}",env="prod"}[5m])
      })
    }

    data {
      ref_id         = "threshold"
      datasource_uid = "__expr__"
      relative_time_range { from = 300; to = 0 }
      model = jsonencode({
        refId      = "threshold"
        type       = "threshold"
        datasource = { type = "__expr__", uid = "__expr__" }
        conditions = [{
          evaluator = { params = [0], type = "lt" }
          operator  = { type = "and" }
          query     = { params = ["metrics"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  # ── ERRORS ───────────────────────────────────────────────────────────────
  rule {
    name      = "${each.key}-error-rate"
    condition = "threshold"
    for       = "5m"

    annotations = {
      service   = each.key
      alliance  = each.value.alliance
      signal    = "errors"
      tier      = each.value.tier
      runbook   = "${each.value.runbook_base_url}/errors"
      summary   = "${each.key} error rate exceeds ${each.value.error_threshold * 100}%"
    }
    labels = {
      severity = each.value.tier == "1" ? "critical" : "warning"
      team     = each.value.oncall_team
    }

    data {
      ref_id         = "metrics"
      datasource_uid = var.datasource_uid
      relative_time_range { from = 300; to = 0 }
      model = jsonencode({
        refId      = "metrics"
        scenarioId = "random_walk"
        alias      = "error_rate"
        # Production swap → expr: rate(http_requests_total{service="${each.key}",env="prod",status=~"5.."}[5m]) / rate(http_requests_total{service="${each.key}",env="prod"}[5m])
      })
    }

    data {
      ref_id         = "threshold"
      datasource_uid = "__expr__"
      relative_time_range { from = 300; to = 0 }
      model = jsonencode({
        refId      = "threshold"
        type       = "threshold"
        datasource = { type = "__expr__", uid = "__expr__" }
        conditions = [{
          evaluator = { params = [each.value.error_threshold], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["metrics"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }

  # ── SATURATION ───────────────────────────────────────────────────────────
  rule {
    name      = "${each.key}-saturation"
    condition = "threshold"
    for       = "10m"

    annotations = {
      service   = each.key
      alliance  = each.value.alliance
      signal    = "saturation"
      tier      = each.value.tier
      runbook   = "${each.value.runbook_base_url}/saturation"
      summary   = "${each.key} capacity utilization exceeds ${each.value.saturation_threshold * 100}%"
    }
    labels = {
      severity = "warning"
      team     = each.value.oncall_team
    }

    data {
      ref_id         = "metrics"
      datasource_uid = var.datasource_uid
      relative_time_range { from = 600; to = 0 }
      model = jsonencode({
        refId      = "metrics"
        scenarioId = "random_walk"
        alias      = "saturation"
        # Production swap → expr: rate(http_requests_total{service="${each.key}",env="prod"}[5m]) / http_service_capacity{service="${each.key}"}
      })
    }

    data {
      ref_id         = "threshold"
      datasource_uid = "__expr__"
      relative_time_range { from = 600; to = 0 }
      model = jsonencode({
        refId      = "threshold"
        type       = "threshold"
        datasource = { type = "__expr__", uid = "__expr__" }
        conditions = [{
          evaluator = { params = [each.value.saturation_threshold], type = "gt" }
          operator  = { type = "and" }
          query     = { params = ["metrics"] }
          reducer   = { params = [], type = "last" }
          type      = "query"
        }]
      })
    }
  }
}
