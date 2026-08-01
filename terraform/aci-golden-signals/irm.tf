##############################################################################
# IRM process for ACI services: one escalation chain, one OnCall integration,
# and one on-call schedule placeholder per service.
#
# Escalations notify the service's Grafana team (created in
# teams_and_folders.tf as "<service>-team") via `notify_team_members` --
# this works even with zero team members configured today (see PR #38);
# once members are added to a team, they'll start receiving notifications
# immediately with no further Terraform changes needed.
#
# The on-call schedules are created empty (no shifts/rotations) as
# placeholders. Add real rotations later via grafana_oncall_on_call_shift
# once you have specific on-call users per service; until then the
# "notify from schedule" step is a no-op and `notify_team_members` is the
# effective escalation path.
#
# NOT wired up yet: pointing the golden-signal alert rules' notification
# route at these OnCall integrations. To do that, create a
# grafana_contact_point of type "oncall" per service (using each
# integration's webhook URL, available as an output after `terraform apply`)
# and update notification_contact_point usage in alerts.tf accordingly.
##############################################################################

resource "grafana_oncall_escalation_chain" "aci_service" {
  for_each = toset(var.aci_services)
  provider = grafana.oncall

  name = "${each.value} Escalation Chain"
}

resource "grafana_oncall_schedule" "aci_service" {
  for_each = toset(var.aci_services)
  provider = grafana.oncall

  name      = "${each.value} On-Call Schedule"
  type      = "calendar"
  time_zone = "UTC"
  # shifts = [] -- add grafana_oncall_on_call_shift IDs here once real
  # rotations/users are defined for this service.
}

resource "grafana_oncall_escalation" "aci_service_notify_schedule" {
  for_each = toset(var.aci_services)
  provider = grafana.oncall

  escalation_chain_id           = grafana_oncall_escalation_chain.aci_service[each.value].id
  type                          = "notify_on_call_from_schedule"
  notify_on_call_from_schedule  = grafana_oncall_schedule.aci_service[each.value].id
  position                      = 0
}

resource "grafana_oncall_escalation" "aci_service_wait" {
  for_each = toset(var.aci_services)
  provider = grafana.oncall

  escalation_chain_id = grafana_oncall_escalation_chain.aci_service[each.value].id
  type                = "wait"
  duration            = 300 # 5 minutes
  position            = 1
}

resource "grafana_oncall_escalation" "aci_service_notify_team" {
  for_each = toset(var.aci_services)
  provider = grafana.oncall

  escalation_chain_id = grafana_oncall_escalation_chain.aci_service[each.value].id
  type                = "notify_team_members"
  team_to_notify       = grafana_team.aci_service[each.value].id
  position             = 2
}

resource "grafana_oncall_integration" "aci_service" {
  for_each = toset(var.aci_services)
  provider = grafana.oncall

  name = "${each.value} Alerting"
  type = "alertmanager"

  default_route {
    escalation_chain_id = grafana_oncall_escalation_chain.aci_service[each.value].id
  }
}

output "aci_oncall_integration_urls" {
  description = "Webhook URLs for each service's OnCall integration -- use these to configure a grafana_contact_point of type 'oncall' per service"
  value       = { for k, v in grafana_oncall_integration.aci_service : k => v.link }
  sensitive   = true
}
