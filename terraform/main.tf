# Grafana Provider Configuration
# Run `terraform init && terraform apply` from this directory

terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = ">= 2.0"
    }
  }
}

provider "grafana" {
  url  = var.grafana_url
  auth = var.grafana_token
}

variable "grafana_url" {
  description = "Your Grafana Cloud URL (e.g. https://yourorg.grafana.net)"
  type        = string
}

variable "grafana_token" {
  description = "Grafana service account token (Editor role)"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub PAT with repo and read:org scopes"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub user or org to pull metrics from"
  type        = string
  default     = "jerome9081227"
}
