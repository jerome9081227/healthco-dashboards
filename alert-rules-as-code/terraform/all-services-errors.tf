resource "grafana_rule_group" "all_services_error_logs" {
  name             = "log-alerts"
  folder_uid       = "ffibotdlti2v4a"
  interval_seconds = 60

  rule {
    name      = "All Services - Error Log Rate"
    condition = "C"
    for       = "5m"

    data {
      ref_id         = "A"
      datasource_uid = "grafanacloud-logs"
      relative_time_range {
        from = 300
        to   = 0
      }
      model = jsonencode({
        refId = "A"
        expr  = "sum(count_over_time({service_name=~\".+\"} |~ \"(?i)error\" [5m]))"
        datasource = {
          type = "loki"
          uid  = "grafanacloud-logs"
        }
      })
    }

    data {
      ref_id         = "B"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        refId      = "B"
        type       = "reduce"
        reducer    = "last"
        expression = "A"
        datasource = {
          uid  = "__expr__"
          type = "__expr__"
        }
      })
    }

    data {
      ref_id         = "C"
      datasource_uid = "__expr__"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = jsonencode({
        refId      = "C"
        type       = "threshold"
        expression = "B"
        conditions = [{
          type = "query"
          evaluator = {
            type   = "gt"
                    params = [10]
          }
          operator = {
            type = "and"
          }
          query = {
            params = ["C"]
          }
          reducer = {
            params = []
            type   = "last"
          }
        }]
        datasource = {
          uid  = "__expr__"
          type = "__expr__"
        }
      })
    }

    annotations = {
            summary = "More than 10 error logs detected in the last 5 minutes across all services"
    }

    no_data_state  = "NoData"
    exec_err_state = "Error"
    is_paused      = false
  }
}
