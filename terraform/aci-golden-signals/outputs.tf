output "dashboard_url" {
  value = grafana_dashboard.aci_golden_signals.url
}

output "alert_rule_groups" {
  value = { for k, v in grafana_rule_group.aci_golden_signals : k => v.name }
}
