##############################################################################
# Synthetic Monitoring HTTP checks for ACI services.
#
# Only aci-storefront has a publicly reachable hostname
# (aci-storefront.salmondesert-baa25d35.eastus.azurecontainerapps.io).
# The other 6 services resolve to *.internal.*.azurecontainerapps.io
# hostnames, which Grafana Synthetic Monitoring's public probes cannot
# reach. Checks for those are intentionally NOT created here.
#
# TODO (blocked): to check aci-accounts, aci-ledger, aci-gateway, aci-fraud,
# and aci-payments:
#   1. Deploy a Synthetic Monitoring PRIVATE PROBE inside the VNet that can
#      resolve *.internal.salmondesert-baa25d35.eastus.azurecontainerapps.io.
#   2. Register it as a grafana_synthetic_monitoring_probe (public = false).
#   3. Add a grafana_synthetic_monitoring_check per service using that
#      probe's ID in `probes`, following the aci_storefront pattern below.
##############################################################################

resource "grafana_synthetic_monitoring_check" "aci_storefront" {
  provider  = grafana.sm
  job       = "aci-storefront-health"
  target    = var.aci_public_targets["aci-storefront"]
  enabled   = true
  frequency = 60000 # 60s, in ms
  timeout   = 10000 # 10s, in ms

  probes = [for p in data.grafana_synthetic_monitoring_probes.main.probes : p.id if contains(var.sm_probes, p.name)]

  labels = {
    service_name = "aci-storefront"
    team         = "aci"
  }

  settings {
    http {
      method             = "GET"
      ip_version         = "V4"
      no_follow_redirects = false
    }
  }
}

data "grafana_synthetic_monitoring_probes" "main" {
  provider = grafana.sm
}

output "aci_storefront_check_id" {
  value = grafana_synthetic_monitoring_check.aci_storefront.id
}
