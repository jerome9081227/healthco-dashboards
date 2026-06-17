# DORA Metrics Dashboard — fixed panel queries and field overrides
# Hides boolean fields (is_draft, is_prerelease, closed) from all visualizations
# Runs terraform apply to update the dashboard in Grafana

resource "grafana_dashboard" "dora_metrics" {
  config_json = jsonencode({
    title    = "DORA Metrics — All Repos"
    uid      = "dora-metrics"
    tags     = ["dora", "engineering", "github"]
    refresh  = "1h"
    time     = { from = "now-30d", to = "now" }
    timezone = "browser"

    templating = {
      list = [{
        name       = "repo"
        label      = "Repository"
        type       = "query"
        datasource = { type = "grafana-github-datasource", uid = "github-dora" }
        query      = { queryType = "Repositories", owner = "jerome9081227" }
        multi      = true
        includeAll = true
        current    = { text = "All", value = "$__all" }
      }]
    }

    panels = [

      # ── Deployment Frequency ─────────────────────────────────────────────
      {
        type    = "row"
        title   = "Deployment Frequency"
        id      = 1
        gridPos = { h = 1, w = 24, x = 0, y = 0 }
      },
      {
        type        = "timeseries"
        title       = "Releases per Day"
        id          = 2
        description = "Each point = one GitHub Release. Draft and pre-releases are hidden. Elite = multiple/day."
        gridPos     = { h = 8, w = 12, x = 0, y = 1 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Releases"
          owner      = "jerome9081227"
          repository = "$repo"
        }]
        transformations = [
          {
            id = "filterFieldsByName"
            options = {
              include = { names = ["publishedAt", "tagName", "name"] }
            }
          }
        ]
        options = {
          tooltip = { mode = "multi" }
          legend  = { displayMode = "list", placement = "bottom" }
        }
        fieldConfig = {
          defaults = {
            custom = { lineWidth = 0, fillOpacity = 0, drawStyle = "points", pointSize = 8 }
            color  = { mode = "fixed", fixedColor = "green" }
          }
          overrides = [
            { matcher = { id = "byName", options = "is_draft" },      properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] },
            { matcher = { id = "byName", options = "is_prerelease" }, properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] }
          ]
        }
      },
      {
        type        = "stat"
        title       = "Total Releases (30d)"
        id          = 3
        description = "Count of releases published in the last 30 days."
        gridPos     = { h = 8, w = 12, x = 12, y = 1 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Releases"
          owner      = "jerome9081227"
          repository = "$repo"
        }]
        options = {
          reduceOptions = { calcs = ["count"] }
          colorMode     = "background"
          textMode      = "auto"
          orientation   = "auto"
        }
        fieldConfig = {
          defaults = {
            thresholds = {
              mode  = "absolute"
              steps = [
                { color = "red",    value = null },
                { color = "yellow", value = 2 },
                { color = "green",  value = 8 }
              ]
            }
            mappings = []
          }
          overrides = [
            { matcher = { id = "byName", options = "is_draft" },      properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] },
            { matcher = { id = "byName", options = "is_prerelease" }, properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] }
          ]
        }
      },

      # ── Lead Time for Changes ─────────────────────────────────────────────
      {
        type    = "row"
        title   = "Lead Time for Changes"
        id      = 10
        gridPos = { h = 1, w = 24, x = 0, y = 9 }
      },
      {
        type        = "table"
        title       = "Recent Merged PRs"
        id          = 11
        description = "Merged PRs in the last 30 days. Lead time = time from PR opened to merged."
        gridPos     = { h = 8, w = 12, x = 0, y = 10 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Pull Requests"
          owner      = "jerome9081227"
          repository = "$repo"
          filters    = [{ field = "state", value = "MERGED" }]
        }]
        transformations = [
          {
            id = "filterFieldsByName"
            options = {
              include = { names = ["title", "createdAt", "mergedAt", "repository"] }
            }
          }
        ]
        options = {
          sortBy = [{ displayName = "mergedAt", desc = true }]
        }
        fieldConfig = {
          defaults = { custom = { align = "auto" } }
          overrides = []
        }
      },
      {
        type        = "stat"
        title       = "PRs Merged (30d)"
        id          = 12
        description = "Total pull requests merged in the last 30 days."
        gridPos     = { h = 8, w = 12, x = 12, y = 10 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Pull Requests"
          owner      = "jerome9081227"
          repository = "$repo"
          filters    = [{ field = "state", value = "MERGED" }]
        }]
        options = {
          reduceOptions = { calcs = ["count"] }
          colorMode     = "background"
        }
        fieldConfig = {
          defaults = {
            thresholds = {
              mode  = "absolute"
              steps = [
                { color = "red",    value = null },
                { color = "yellow", value = 2 },
                { color = "green",  value = 8 }
              ]
            }
          }
          overrides = []
        }
      },

      # ── Change Failure Rate ───────────────────────────────────────────────
      {
        type    = "row"
        title   = "Change Failure Rate"
        id      = 20
        gridPos = { h = 1, w = 24, x = 0, y = 18 }
      },
      {
        type        = "table"
        title       = "Hotfix / Rollback Releases"
        id          = 21
        description = "Releases with 'hotfix' or 'rollback' in the tag name."
        gridPos     = { h = 8, w = 12, x = 0, y = 19 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Releases"
            owner      = "jerome9081227"
            repository = "$repo"
            filters    = [{ field = "tagName", value = "hotfix" }]
          },
          {
            refId      = "B"
            queryType  = "Releases"
            owner      = "jerome9081227"
            repository = "$repo"
            filters    = [{ field = "tagName", value = "rollback" }]
          }
        ]
        transformations = [
          {
            id = "filterFieldsByName"
            options = {
              include = { names = ["tagName", "name", "publishedAt", "repository"] }
            }
          }
        ]
        fieldConfig = {
          defaults  = { custom = { align = "auto" } }
          overrides = []
        }
      },
      {
        type        = "stat"
        title       = "Hotfix Releases (30d)"
        id          = 22
        description = "Count of releases tagged with 'hotfix-' or 'rollback-'. Target = 0."
        gridPos     = { h = 8, w = 12, x = 12, y = 19 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [
          {
            refId      = "A"
            queryType  = "Releases"
            owner      = "jerome9081227"
            repository = "$repo"
            filters    = [{ field = "tagName", value = "hotfix" }]
          },
          {
            refId      = "B"
            queryType  = "Releases"
            owner      = "jerome9081227"
            repository = "$repo"
            filters    = [{ field = "tagName", value = "rollback" }]
          }
        ]
        options = {
          reduceOptions = { calcs = ["count"] }
          colorMode     = "background"
        }
        fieldConfig = {
          defaults = {
            thresholds = {
              mode  = "absolute"
              steps = [
                { color = "green",  value = null },
                { color = "yellow", value = 1 },
                { color = "red",    value = 3 }
              ]
            }
          }
          overrides = []
        }
      },

      # ── MTTR ─────────────────────────────────────────────────────────────
      {
        type    = "row"
        title   = "Mean Time to Recovery (MTTR)"
        id      = 30
        gridPos = { h = 1, w = 24, x = 0, y = 27 }
      },
      {
        type        = "table"
        title       = "Closed Incidents"
        id          = 31
        description = "GitHub Issues labeled 'incident' that have been closed."
        gridPos     = { h = 8, w = 12, x = 0, y = 28 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Issues"
          owner      = "jerome9081227"
          repository = "$repo"
          filters    = [
            { field = "label", value = "incident" },
            { field = "state", value = "CLOSED" }
          ]
        }]
        transformations = [
          {
            id = "filterFieldsByName"
            options = {
              include = { names = ["title", "createdAt", "closedAt", "repository"] }
            }
          }
        ]
        options = {
          sortBy = [{ displayName = "closedAt", desc = true }]
        }
        fieldConfig = {
          defaults  = { custom = { align = "auto" } }
          overrides = []
        }
      },
      {
        type        = "stat"
        title       = "Median MTTR (30d)"
        id          = 32
        description = "Median time to close 'incident' labeled issues."
        gridPos     = { h = 8, w = 12, x = 12, y = 28 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Issues"
          owner      = "jerome9081227"
          repository = "$repo"
          filters    = [
            { field = "label", value = "incident" },
            { field = "state", value = "CLOSED" }
          ]
        }]
        options = {
          reduceOptions = { calcs = ["mean"] }
          colorMode     = "background"
        }
        fieldConfig = {
          defaults = {
            unit = "h"
            thresholds = {
              mode  = "absolute"
              steps = [
                { color = "green",  value = null },
                { color = "yellow", value = 24 },
                { color = "red",    value = 168 }
              ]
            }
          }
          overrides = [
            { matcher = { id = "byName", options = "closed" }, properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] },
            { matcher = { id = "byName", options = "number" }, properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] }
          ]
        }
      }
    ]
  })

  depends_on = [grafana_data_source.github]
}
