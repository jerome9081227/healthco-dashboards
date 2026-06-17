# GitHub Datasource
# Requires grafana-github-datasource plugin installed in Grafana

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
