# Mock Workflow Debrief: DORA Metrics via GitHub + Grafana Terraform
**Date:** 2026-06-16  
**Session:** DORA dashboard provisioned via Terraform, GitHub datasource, GitHub Actions auto-generator

---

## 🎯 What I Can Tell Customers (Top 5–7 Insights)

- **DORA via Terraform** — "I personally provisioned a full DORA metrics dashboard in Grafana using Terraform — GitHub datasource, all 4 metrics, color-coded thresholds — in one `terraform apply`. No ClickOps, no manual panel config."
- **GitHub as a metrics source, not just a code host** — "The Grafana GitHub datasource turns your repo activity — releases, PRs, issues — into live engineering metrics. No data pipeline, no ETL, no separate DORA tool to buy."
- **SLO-as-Code alongside DORA** — "We pushed Terraform SLO configs for AI service error rate and patient vitals availability to the same repo that feeds the DORA dashboard — so reliability targets and performance visibility live in the same git history."
- **GitHub Actions auto-generates DORA signal** — "We wired a weekly workflow that creates a branch, opens a PR, merges it, and cuts a release automatically — so the dashboard always has fresh data, even without manual deployments."
- **Token scope is the first enterprise blocker** — "Every auth failure I hit was a permissions gap — read-only tokens, missing Contents:write, revoked PATs. Enterprise platform teams need to design this upfront, not discover it at the first push."
- **Branch protection blocks automated DORA data generation** — "Required approvals and required status checks — like a k6 smoke test gate — blocked the automated PR merge. That's actually a good sign for mature teams, but they need a bypass strategy for bot-generated DORA PRs."

---

## 🏢 How Enterprise Does This at Scale

- **One Terraform module, 500 repos** — A platform team owns the DORA dashboard module; product teams inherit it via a shared Terraform registry. Each squad gets the same dashboard pointed at their repo with no bespoke work.
- **GitHub App replaces PATs** — At scale, no personal tokens. A GitHub App is created per environment, scoped to `Contents:write` on infra repos only, managed as a service account. Token rotation is automated via secrets management (Vault, AWS Secrets Manager).
- **Branch protection exemptions are policy, not workarounds** — Regulated orgs (healthcare, fintech) gate human PRs with required reviews and CI checks, but create a bot allowlist for automated DORA activity PRs. This is a platform governance decision, not a dev decision.
- **`incident` label is owned by the SRE team** — MTTR only works if incident labeling is disciplined. Mature orgs have PagerDuty or incident.io auto-creating and auto-labeling GitHub Issues on alert fire, then closing them on resolution — zero manual labeling.
- **DORA thresholds become SLOs** — Elite teams set Grafana alerts on DORA metrics (e.g., alert if no release in 14 days, alert if MTTR > 48 hours) and route to the same incident workflow. DORA stops being a reporting dashboard and becomes an operational signal.

---

## ⚠️ Gotchas & Friction Points

- **GitHub datasource returns boolean fields as time series** — `is_draft` and `is_prerelease` were plotted as True/False lines instead of release counts. Fix: use `filterFieldsByName` transformations or switch to table panels; timeseries panels need a numeric Y field.
- **Datasource plugin must be installed before Terraform can create it** — `terraform apply` succeeded but the dashboard showed "datasource not found." Fix: install `grafana-github-datasource` from the Grafana plugin catalog first, then apply.
- **401 on first apply = wrong token type** — Using a Grafana Cloud API key (from grafana.com) instead of a service account token (from inside the Grafana instance) produces identical 401 errors with different root causes. Fix: always create the service account at `yourinstance.grafana.net/org/serviceaccounts`.
- **Revoking a leaked PAT mid-session breaks the datasource silently** — After revoking the accidentally-posted token, the Grafana GitHub datasource went dark with no visible error until panels showed "No data." Fix: immediately update the datasource token after any revocation.
- **GitHub Actions can't create PRs by default** — `createPullRequest` fails with 403 unless "Allow GitHub Actions to create and approve pull requests" is enabled in repo settings. Fix: one checkbox in Settings → Actions → Workflow permissions.
- **Branch protection blocks automated merges** — Required review + required `k6-smoke` status check blocked the auto-merge step. Fix: either exempt the bot from protection rules, or switch the workflow to push directly to main for DORA signal commits.
- **MCP session restart required after token update** — Updating GitHub MCP credentials mid-session doesn't reload tools in the current chat. Fix: always refresh the page after any MCP reconfiguration.

---

## ⚡ 3-Arrow Cheat Sheet Entries

```
De-risk Operations
DORA Metrics from GitHub in One Terraform Apply ★ signpost
team has no visibility into deployment frequency or MTTR→Grafana GitHub datasource + Terraform provisions all 4 DORA panels→engineering leadership sees elite vs. low performer gaps in 30 minutes — no separate DORA tooling license, no data pipeline, no ClickOps
```

```
Dev Productivity
Automated DORA Signal via GitHub Actions
dashboard shows stale or empty DORA metrics because deployments are infrequent→GitHub Actions workflow runs weekly: branch, PR, merge, release→DORA panels always have fresh data — consistent signal without waiting for real deployments to accumulate
```

```
De-risk Operations
SLO-as-Code Alongside DORA ★ signpost
SLO targets live in someone's head or a wiki page→Terraform SLO configs are committed to the same repo that feeds the DORA dashboard→reliability targets and performance visibility share a git history — audit trail is automatic, drift is a PR review
```

---

## 💬 Discovery & Objection Handling

**Discovery questions:**
- "How does your team currently track deployment frequency and MTTR — spreadsheet, a separate tool, or not at all?"
- "When an incident happens, how does it get logged and how do you measure time to resolution today?"
- "Does your platform team have a standard for how bots and automation authenticate to GitHub — GitHub Apps, PATs, service accounts?"
- "If your engineering leaders could see DORA metrics for every team in one dashboard, what decision would they make first?"
- "Are your SLO targets defined in code, or are they configured manually in a UI somewhere?"

**Objection handles:**
- **"We already have a DORA tool"** → What you already have is probably a standalone product with its own data pipeline and license cost. This is the GitHub data you already own, surfaced in the same Grafana instance your SREs are already in — no new vendor, no new contract.
- **"Setting up all those permissions sounds like a security risk"** → Every permission we needed was explicit and auditable: `Contents:write` on specific repos, a scoped service account with Editor role. I hit every one of those walls myself — the model is least-privilege by design, not by accident.

---

## 📋 Reference Summary (What Good Looks Like)

1. `grafana-github-datasource` plugin is installed in the Grafana instance before any Terraform is applied.
2. A GitHub App (not a PAT) is used for the datasource — scoped to `Contents:write` on infra repos only, owned by a service account.
3. All 4 DORA panels use Grafana `filterByValue` or `filterFieldsByName` transformations — no boolean fields visible in any visualization.
4. GitHub Actions workflow runs on a schedule, generating weekly release + merged PR activity so the dashboard never runs dry.
5. Incident issues are labeled `incident` automatically (via PagerDuty/incident.io integration) and closed on resolution — MTTR requires no manual tagging.
6. Hotfix and rollback releases use a consistent tag prefix (`hotfix-`, `rollback-`) enforced by release runbook or CI check.
7. Branch protection exempts the DORA activity bot from required reviews and status checks, or the workflow commits directly to a dedicated metrics branch.
8. SLO Terraform configs live in the same repo as the DORA dashboard configs — one `terraform apply` covers both reliability targets and observability.
