# Copy this file to terraform.tfvars and fill in your values
# NEVER commit terraform.tfvars to git — it contains secrets
# Add terraform.tfvars to your .gitignore

# Your Grafana Cloud URL (e.g. https://yourorg.grafana.net)
grafana_url = "https://jeromewwallace.grafana.net"

# Grafana service account token
# Create one at: https://jeromewwallace.grafana.net/org/serviceaccounts
# Role required: Editor
grafana_token = "glsa_xxxxxxxxxxxxxxxxxxxx"

# GitHub Personal Access Token
# Create one at: https://github.com/settings/tokens
# Scopes required: repo (full), read:org
github_token = "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"

# GitHub account or org to pull metrics from
github_owner = "jerome9081227"
