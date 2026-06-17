# ---------------------------------------------------------------------------
# Coverage outputs — visible on terraform apply
# ---------------------------------------------------------------------------

output "total_services_covered" {
  description = "Total number of services with alert coverage. Should equal length(var.services)."
  value       = length(var.services)
}

output "services_by_alliance" {
  description = "Coverage count broken down by alliance."
  value = {
    for alliance in toset([for svc in var.services : svc.alliance]) :
    alliance => length([for name, svc in var.services : name if svc.alliance == alliance])
  }
}

output "tier1_services" {
  description = "Tier 1 services covered (customer-critical path)."
  value       = [for name, svc in var.services : name if svc.tier == "1"]
}

output "total_alert_rules_created" {
  description = "Total alert rules created (services × 4 golden signals)."
  value       = length(var.services) * 4
}

output "rule_group_ids" {
  description = "Map of service → Grafana rule group UID"
  value       = { for k, v in grafana_rule_group.golden_signals : k => v.id }
}
