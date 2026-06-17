# GitHub Datasource for DORA Metrics
# Requires: grafana-github-datasource plugin installed in your Grafana instance
# Plugin docs: https://grafana.com/grafana/plugins/grafana-github-datasource/

variable "github_token" {
  description = "GitHub Personal Access Token with repo and read:org scopes"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or user to pull metrics from (e.g. jerome9081227)"
  type        = string
  default     = "jerome9081227"
}

resource "grafana_data_source" "github" {
  type = "grafana-github-datasource"
  name = "GitHub"
  uid  = "github-dora"

  json_data_encoded = jsonencode({
    owner = var.github_owner
  })

  secure_json_data_encoded = jsonencode({
    accessToken = var.github_token
  })
}
