terraform {
  required_version = ">= 1.5"
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 3.7"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}

# ---------------------------------------------------------------------------
# Folders — one per alliance, derived from the service registry
# ---------------------------------------------------------------------------
# We use toset() on the alliance values so each alliance folder is created
# exactly once, even if multiple services share an alliance.
# ---------------------------------------------------------------------------

locals {
  alliances = toset([for svc in var.services : svc.alliance])
}

resource "grafana_folder" "alliance" {
  for_each = local.alliances
  title    = "${each.key}-alerts"
}
