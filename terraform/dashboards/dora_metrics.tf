# DORA Metrics Dashboard
# Surfaces all 4 DORA metrics from GitHub via the grafana-github-datasource
#
# Metrics covered:
#   1. Deployment Frequency   — GitHub Releases per day/week
#   2. Lead Time for Changes  — PR merge time (created_at → merged_at)
#   3. Change Failure Rate    — Releases tagged as hotfix / rollback
#   4. MTTR                   — Time to close issues labeled 'incident'
#
# Prerequisites:
#   - grafana-github-datasource plugin installed
#   - terraform/datasources/github.tf applied first
#   - GitHub token with repo + read:org scopes

locals {
  dora_dashboard = {
    title       = "DORA Metrics — All Repos"
    uid         = "dora-metrics"
    tags        = ["dora", "engineering", "github"]
    timezone    = "browser"
    refresh     = "1h"
    time_from   = "now-30d"
    time_to     = "now"
  }
}

resource "grafana_dashboard" "dora_metrics" {
  config_json = jsonencode({
    title   = local.dora_dashboard.title
    uid     = local.dora_dashboard.uid
    tags    = local.dora_dashboard.tags
    refresh = local.dora_dashboard.refresh
    time = {
      from = local.dora_dashboard.time_from
      to   = local.dora_dashboard.time_to
    }
    timezone = local.dora_dashboard.timezone

    templating = {
      list = [
        {
          name    = "repo"
          label   = "Repository"
          type    = "query"
          datasource = { type = "grafana-github-datasource", uid = "github-dora" }
          query   = { queryType = "Repositories", owner = "${var.github_owner}" }
          multi   = true
          includeAll = true
          current = { text = "All", value = "$__all" }
        }
      ]
    }

    panels = [
      # ── Row: Deployment Frequency ─────────────────────────────────────────
      {
        type  = "row"
        title = "Deployment Frequency"
        id    = 1
        gridPos = { h = 1, w = 24, x = 0, y = 0 }
      },
      {
        type  = "timeseries"
        title = "Releases per Day"
        id    = 2
        description = "Number of GitHub Releases published per day across selected repos. Elite = multiple per day; High = weekly."
        gridPos = { h = 8, w = 12, x = 0, y = 1 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId     = "A"
            queryType = "Releases"
            owner     = "${var.github_owner}"
            repository = "$repo"
          }
        ]
        options = {
          tooltip = { mode = "multi" }
        }
        fieldConfig = {
          defaults = {
            custom = { lineWidth = 2, fillOpacity = 10 }
            color  = { mode = "palette-classic" }
          }
        }
      },
      {
        type  = "stat"
        title = "Avg Deployments / Day (30d)"
        id    = 3
        gridPos = { h = 8, w = 12, x = 12, y = 1 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId     = "A"
            queryType = "Releases"
            owner     = "${var.github_owner}"
            repository = "$repo"
          }
        ]
        options = {
          reduceOptions = { calcs = ["count"] }
          orientation   = "auto"
          textMode      = "auto"
          colorMode     = "background"
        }
        fieldConfig = {
          defaults = {
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "red",    value = null },
                { color = "yellow", value = 1 },
                { color = "green",  value = 7 }
              ]
            }
          }
        }
      },

      # ── Row: Lead Time for Changes ─────────────────────────────────────────
      {
        type  = "row"
        title = "Lead Time for Changes"
        id    = 10
        gridPos = { h = 1, w = 24, x = 0, y = 9 }
      },
      {
        type  = "timeseries"
        title = "PR Merge Time (hours)"
        id    = 11
        description = "Time from PR opened to merged. Elite < 1 hour; High < 1 day; Medium < 1 week."
        gridPos = { h = 8, w = 12, x = 0, y = 10 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Pull Requests"
            owner      = "${var.github_owner}"
            repository = "$repo"
            filters    = [{ field = "state", value = "MERGED" }]
          }
        ]
        transformations = [
          {
            id = "calculateField"
            options = {
              alias  = "Lead Time (hrs)"
              mode   = "reduceRow"
              reduce = { reducer = "diff" }
            }
          }
        ]
        fieldConfig = {
          defaults = {
            unit   = "h"
            custom = { lineWidth = 2, fillOpacity = 10 }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green",  value = null },
                { color = "yellow", value = 24 },
                { color = "red",    value = 168 }
              ]
            }
          }
        }
      },
      {
        type  = "stat"
        title = "Median Lead Time (30d)"
        id    = 12
        gridPos = { h = 8, w = 12, x = 12, y = 10 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Pull Requests"
            owner      = "${var.github_owner}"
            repository = "$repo"
            filters    = [{ field = "state", value = "MERGED" }]
          }
        ]
        options = {
          reduceOptions = { calcs = ["mean"] }
          colorMode     = "background"
        }
        fieldConfig = {
          defaults = {
            unit = "h"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green",  value = null },
                { color = "yellow", value = 24 },
                { color = "red",    value = 168 }
              ]
            }
          }
        }
      },

      # ── Row: Change Failure Rate ───────────────────────────────────────────
      {
        type  = "row"
        title = "Change Failure Rate"
        id    = 20
        gridPos = { h = 1, w = 24, x = 0, y = 18 }
      },
      {
        type  = "timeseries"
        title = "Hotfix / Rollback Releases"
        id    = 21
        description = "Releases with 'hotfix' or 'rollback' in the tag name. Elite < 5%; High < 10%."
        gridPos = { h = 8, w = 12, x = 0, y = 19 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Releases"
            owner      = "${var.github_owner}"
            repository = "$repo"
            filters    = [{ field = "tagName", value = "hotfix" }]
          },
          {
            refId      = "B"
            queryType  = "Releases"
            owner      = "${var.github_owner}"
            repository = "$repo"
            filters    = [{ field = "tagName", value = "rollback" }]
          }
        ]
        fieldConfig = {
          defaults = {
            custom = { lineWidth = 2, fillOpacity = 10 }
            color  = { fixedColor = "red", mode = "fixed" }
          }
        }
      },
      {
        type  = "stat"
        title = "Change Failure Rate %"
        id    = 22
        description = "(Hotfix + Rollback releases) / Total releases × 100"
        gridPos = { h = 8, w = 12, x = 12, y = 19 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Releases"
            owner      = "${var.github_owner}"
            repository = "$repo"
          }
        ]
        options = {
          reduceOptions = { calcs = ["count"] }
          colorMode     = "background"
        }
        fieldConfig = {
          defaults = {
            unit = "percent"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green",  value = null },
                { color = "yellow", value = 5 },
                { color = "red",    value = 15 }
              ]
            }
          }
        }
      },

      # ── Row: MTTR ──────────────────────────────────────────────────────────
      {
        type  = "row"
        title = "Mean Time to Recovery (MTTR)"
        id    = 30
        gridPos = { h = 1, w = 24, x = 0, y = 27 }
      },
      {
        type  = "timeseries"
        title = "Incident Resolution Time (hours)"
        id    = 31
        description = "Time to close GitHub Issues labeled 'incident'. Elite < 1 hour; High < 1 day."
        gridPos = { h = 8, w = 12, x = 0, y = 28 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Issues"
            owner      = "${var.github_owner}"
            repository = "$repo"
            filters    = [
              { field = "label",  value = "incident" },
              { field = "state",  value = "CLOSED" }
            ]
          }
        ]
        fieldConfig = {
          defaults = {
            unit   = "h"
            custom = { lineWidth = 2, fillOpacity = 10 }
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green",  value = null },
                { color = "yellow", value = 24 },
                { color = "red",    value = 168 }
              ]
            }
          }
        }
      },
      {
        type  = "stat"
        title = "Median MTTR (30d)"
        id    = 32
        gridPos = { h = 8, w = 12, x = 12, y = 28 }
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Issues"
            owner      = "${var.github_owner}"
            repository = "$repo"
            filters    = [
              { field = "label", value = "incident" },
              { field = "state", value = "CLOSED" }
            ]
          }
        ]
        options = {
          reduceOptions = { calcs = ["mean"] }
          colorMode     = "background"
        }
        fieldConfig = {
          defaults = {
            unit = "h"
            thresholds = {
              mode = "absolute"
              steps = [
                { color = "green",  value = null },
                { color = "yellow", value = 24 },
                { color = "red",    value = 168 }
              ]
            }
          }
        }
      }
    ]
  })
}
