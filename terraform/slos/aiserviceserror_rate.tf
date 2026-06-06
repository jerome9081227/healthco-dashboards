resource "grafana_slo" "ai_services_error_rate" {
  name        = "AI Services Error Rate"
  description = "Measures the error rate for AI services. Fires when the proportion of failed requests exceeds the SLO threshold."

  objectives {
    value  = 0.99
    window = "30d"
  }

  query {
    type = "ratio"

    ratio {
      success_metric {
        type = "prometheus"
        prometheus_metric {
          expr = "sum(rate(http_requests_total{service=~\"ai-.*\", status!~\"5..\"}[5m]))"
        }
      }

      total_metric {
        type = "prometheus"
        prometheus_metric {
          expr = "sum(rate(http_requests_total{service=~\"ai-.*\"}[5m]))"
        }
      }
    }
  }

  alerting {
    fastburn {
      annotation {
        key   = "summary"
        value = "AI Services error rate fast burn"
      }
      label {
        key   = "severity"
        value = "critical"
      }
    }

    slowburn {
      annotation {
        key   = "summary"
        value = "AI Services error rate slow burn"
      }
      label {
        key   = "severity"
        value = "warning"
      }
    }
  }

  label {
    key   = "team"
    value = "ai-platform"
  }

  label {
    key   = "service"
    value = "ai-services"
  }
}
