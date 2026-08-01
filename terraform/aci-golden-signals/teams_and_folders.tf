##############################################################################
# Per-service Grafana teams and folders for ACI services.
#
# One team + one folder per service, each team granted Edit access to its
# own folder. Teams are created empty (no members) — add members later via
# grafana_team_external_group or by editing team membership.
##############################################################################

resource "grafana_team" "aci_service" {
  for_each = toset(var.aci_services)

  name  = "${each.value}-team"
  email = "" # set a team email later if desired
}

resource "grafana_folder" "aci_service" {
  for_each = toset(var.aci_services)

  title = "${each.value} (ACI)"
}

resource "grafana_folder_permission" "aci_service" {
  for_each = toset(var.aci_services)

  folder_uid = grafana_folder.aci_service[each.value].uid

  permissions {
    team_id    = grafana_team.aci_service[each.value].id
    permission = "Edit"
  }
}

output "aci_service_teams" {
  value = { for k, v in grafana_team.aci_service : k => v.id }
}

output "aci_service_folders" {
  value = { for k, v in grafana_folder.aci_service : k => v.uid }
}
