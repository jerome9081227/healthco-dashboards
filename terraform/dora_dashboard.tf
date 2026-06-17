# DORA Metrics Dashboard
# Uses table panels throughout — avoids "missing number field" errors
# from the GitHub datasource returning only string/boolean fields

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
        type        = "table"
        title       = "Recent Releases"
        id          = 2
        description = "All non-draft releases. Each row = one deployment. Elite = multiple per day."
        gridPos     = { h = 8, w = 16, x = 0, y = 1 }
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
            options = { include = { names = ["tagName", "name", "publishedAt", "repository"] } }
          },
          {
            id      = "sortBy"
            options = { fields = [{ desc = true, displayName = "publishedAt" }] }
          }
        ]
        options = { footer = { show = false } }
        fieldConfig = {
          defaults  = { custom = { align = "auto" } }
          overrides = []
        }
      },
      {
        type        = "stat"
        title       = "Total Releases (30d)"
        id          = 3
        description = "Count of releases in the last 30 days. Green = 8+, Yellow = 2+, Red = <2."
        gridPos     = { h = 8, w = 8, x = 16, y = 1 }
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
            options = { include = { names = ["tagName"] } }
          }
        ]
        options = {
          reduceOptions = { calcs = ["count"], fields = "/^tagName$/", values = false }
          colorMode     = "background"
          textMode      = "auto"
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

      # ── Lead Time for Changes ─────────────────────────────────────────────
      {
        type    = "row"
        title   = "Lead Time for Changes"
        id      = 10
        gridPos = { h = 1, w = 24, x = 0, y = 9 }
      },
      {
        type        = "table"
        title       = "Recent Pull Requests"
        id          = 11
        description = "Merged PRs — lead time = gap between createdAt and mergedAt."
        gridPos     = { h = 8, w = 16, x = 0, y = 10 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Pull Requests"
          owner      = "jerome9081227"
          repository = "$repo"
        }]
        transformations = [
          {
            id = "filterFieldsByName"
            options = { include = { names = ["title", "state", "createdAt", "mergedAt", "repository"] } }
          },
          {
            id      = "filterByValue"
            options = {
              filters = [{ fieldName = "state", config = { id = "equal", options = { value = "MERGED" } } }]
              match   = "any"
              type    = "include"
            }
          },
          {
            id      = "sortBy"
            options = { fields = [{ desc = true, displayName = "mergedAt" }] }
          }
        ]
        options = { footer = { show = false } }
        fieldConfig = {
          defaults  = { custom = { align = "auto" } }
          overrides = []
        }
      },
      {
        type        = "stat"
        title       = "PRs Merged (30d)"
        id          = 12
        description = "Total pull requests merged in the last 30 days."
        gridPos     = { h = 8, w = 8, x = 16, y = 10 }
        datasource  = { type = "grafana-github-datasource", uid = "github-dora" }
        targets = [{
          refId      = "A"
          queryType  = "Pull Requests"
          owner      = "jerome9081227"
          repository = "$repo"
        }]
        transformations = [
          {
            id = "filterFieldsByName"
            options = { include = { names = ["title", "state"] } }
          },
          {
            id      = "filterByValue"
            options = {
              filters = [{ fieldName = "state", config = { id = "equal", options = { value = "MERGED" } } }]
              match   = "any"
              type    = "include"
            }
          }
        ]
        options = {
          reduceOptions = { calcs = ["count"], fields = "/^title$/", values = false }
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
        description = "Releases whose tag starts with 'hotfix-' or 'rollback-'."
        gridPos     = { h = 8, w = 16, x = 0, y = 19 }
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
            options = { include = { names = ["tagName", "name", "publishedAt", "repository"] } }
          },
          {
            id      = "filterByValue"
            options = {
              filters = [
                { fieldName = "tagName", config = { id = "includesSubstring", options = { value = "hotfix" } } },
                { fieldName = "tagName", config = { id = "includesSubstring", options = { value = "rollback" } } }
              ]
              match = "any"
              type  = "include"
            }
          }
        ]
        options = { footer = { show = false } }
        fieldConfig = {
          defaults  = { custom = { align = "auto" } }
          overrides = []
        }
      },
      {
        type        = "stat"
        title       = "Hotfix Releases (30d)"
        id          = 22
        description = "Count of hotfix/rollback releases. Target = 0 (green)."
        gridPos     = { h = 8, w = 8, x = 16, y = 19 }
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
            options = { include = { names = ["tagName"] } }
          },
          {
            id      = "filterByValue"
            options = {
              filters = [
                { fieldName = "tagName", config = { id = "includesSubstring", options = { value = "hotfix" } } },
                { fieldName = "tagName", config = { id = "includesSubstring", options = { value = "rollback" } } }
              ]
              match = "any"
              type  = "include"
            }
          }
        ]
        options = {
          reduceOptions = { calcs = ["count"], fields = "/^tagName$/", values = false }
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
        gridPos     = { h = 8, w = 16, x = 0, y = 28 }
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
            options = { include = { names = ["title", "createdAt", "closedAt", "repository"] } }
          },
          {
            id      = "sortBy"
            options = { fields = [{ desc = true, displayName = "closedAt" }] }
          }
        ]
        options = { footer = { show = false } }
        fieldConfig = {
          defaults  = { custom = { align = "auto" } }
          overrides = []
        }
      },
      {
        type        = "stat"
        title       = "Median MTTR (30d)"
        id          = 32
        description = "Median time to resolve an 'incident' labeled issue."
        gridPos     = { h = 8, w = 8, x = 16, y = 28 }
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
            { matcher = { id = "byName", options = "closed" },  properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] },
            { matcher = { id = "byName", options = "number" }, properties = [{ id = "custom.hideFrom", value = { legend = true, tooltip = true, viz = true } }] }
          ]
        }
      }
    ]
  })

  depends_on = [grafana_data_source.github]
}
