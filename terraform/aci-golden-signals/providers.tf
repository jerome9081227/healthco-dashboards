terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.0"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_auth
}

# Synthetic Monitoring uses a separate access token/URL from the main provider.
provider "grafana" {
  alias   = "sm"
  sm_url  = var.sm_url
  sm_access_token = var.sm_access_token
}

# Grafana IRM/OnCall also uses a separate access token/URL.
provider "grafana" {
  alias       = "oncall"
  url         = var.grafana_url
  auth        = var.grafana_auth
  oncall_url  = var.oncall_url
}

