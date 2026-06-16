# Mock Workflow Debrief: GitHub MCP + Grafana-as-Code
**Date:** 2026-06-16  
**Session:** Terraform SLO push via Grafana AI Assistant → GitHub MCP

---

## 🎯 What I Can Tell Customers (Top 5–7 Insights)

- **Grafana-as-Code via MCP** — "I've personally pushed Terraform SLO configs directly to GitHub from within Grafana's AI assistant — no local CLI, no context-switching. The SLO definition lives in source control from day one."
- **SLO-as-Code for AI services** — "We generate and commit Terraform for service-level objectives on AI error rates — which means SLO drift is a PR, not a YAML edit on someone's laptop."
- **MCP is the integration layer that actually matters** — "The GitHub MCP server exposes 44 tools — push files, create branches, open PRs — all callable from the AI assistant. Your engineers don't need to leave the chat interface to commit infra config."
- **Token/scope hygiene is a real enterprise problem** — "The first blocker we hit is the same one your platform team will hit: MCP integration tokens default to read-only, and nobody realizes it until the first write operation fails."
- **Grafana connects to Claude via service account tokens** — "You can wire a Grafana Cloud instance into Claude Desktop the same way — service account token, MCP server config, done. Your on-call engineers get natural language access to dashboards and metrics from wherever they work."
- **Session restart is required after MCP reconfiguration** — "If you update an MCP integration mid-session, the current chat doesn't pick up the new tools — you have to refresh. That's a workflow to document for your platform team."

---

## 🏢 How Enterprise Does This at Scale

- **SLO-as-Code at 500 services** — A platform team owns the Terraform SLO templates; product teams submit PRs to add their service. The AI assistant generates the config, platform team reviews and merges. No one writes SLO YAML from scratch.
- **GitHub App over PAT** — Enterprise orgs won't use personal PATs for shared tooling. They create a GitHub App scoped to specific repos, managed by a service account, with fine-grained permissions enforced by org policy. The MCP server authenticates as the app, not a person.
- **Contents:write is a controlled permission** — In regulated environments (healthcare, fintech), write access to infra repos is gated behind approval workflows. The MCP integration would need to be approved as a "trusted deployer" before it can push to main.
- **MCP tool inventory is a governance artifact** — 44 tools enabled by default is too many for most enterprise security teams. They'll want a read-only profile for general use and a separate write-enabled profile for platform engineers.
- **Grafana-to-Claude connection uses service accounts, not personal tokens** — At scale, each team gets a scoped service account (Viewer or Editor role, not Admin) so Claude's access mirrors what that team is authorized to see.

---

## ⚠️ Gotchas & Friction Points

- **Original GitHub MCP token was read-only** — The integration connected successfully and showed tools, but the first push returned 403. No warning in the UI that write scope was missing. Fix: always verify `Contents: Read & write` at setup, not at first use.
- **GitHub App name collision** — `jmoney` was reserved by another account. GitHub gives no suggestions. Fix: use a scoped name like `org-grafana-mcp` or `{account}-grafana`.
- **GitHub App created with Metadata-only (default)** — The UI defaults to 1 mandatory permission. Contents:write has to be explicitly added — it's buried in a long permission list and easy to miss. Fix: check Contents before hitting Create.
- **"No tools available" after MCP reconnect** — After removing and re-adding the GitHub MCP server, the current chat session lost all GitHub tools. The page has to be fully refreshed. Fix: always refresh after any MCP reconfiguration.
- **PAT scope confusion** — `public_repo` vs `repo` (full) scope produces the same 403 error with different root causes. GitHub doesn't distinguish in the error message. Fix: always generate PATs with `repo` (full) scope for write use cases.
- **MCP tool list ≠ MCP auth config** — The "Tools" settings page shows tool toggles; the token lives on a different settings view. Easy to end up on the wrong screen. Fix: if you're looking at 44 tool toggles, you're in the wrong place — go back to the server config.

---

## ⚡ 3-Arrow Cheat Sheet Entries

```
De-risk Operations
Terraform SLO as Code via AI Assistant ★ signpost
team defines SLOs ad-hoc in the UI→AI assistant generates Terraform SLO config on demand→config is committed to GitHub in a single operation — SLO drift becomes a PR review, not a config file on someone's laptop
```

```
Dev Productivity
GitHub MCP Write Access for Infra Automation
MCP integration defaults to read-only scope→first write operation hits 403 and blocks the workflow→fix is a one-time permission update to Contents:write — platform teams that audit this upfront never hit the wall
```

```
De-risk Operations
Grafana-to-Claude via Service Account Token
engineers query dashboards in Claude Desktop without leaving their workflow→Grafana MCP server authenticates via service account token→scoped access mirrors team permissions — no personal credentials, no shared admin tokens in chat
```

---

## 💬 Discovery & Objection Handling

**Discovery questions:**
- "How are your SLOs defined today — in a UI, in code, or somewhere in between?"
- "When someone changes an SLO threshold, how does that change get reviewed and tracked?"
- "Does your platform team have a standard for how AI tooling authenticates to internal systems — GitHub Apps, PATs, service accounts?"
- "If your on-call engineers could query Grafana dashboards from their chat interface, what's the first thing they'd ask?"
- "How many MCP integrations does your team currently run, and who owns the token rotation?"

**Objection handles:**
- **"We can't give an AI assistant write access to our infra repos"** → The GitHub MCP permission model is granular — you can scope it to `Contents:write` on specific repos only, gated by a GitHub App that your security team approves. It's the same trust boundary as a deploy bot.
- **"Setting this up sounds complicated"** → The hardest part is getting the token scope right on day one. I hit that myself — once it's resolved, pushing Terraform configs from the assistant is a single command with no CLI required.

---

## 📋 Reference Summary (What Good Looks Like)

1. GitHub MCP server is connected with a GitHub App (not a PAT) scoped to `Contents: Read & write` on the target repo only.
2. The GitHub App is installed on the specific repository — not just created but actually installed under the account.
3. SLO Terraform configs are generated by the AI assistant and committed to a `terraform/slos/` path in a shared infra repo.
4. After any MCP reconfiguration, the user refreshes the page before retrying — tool registration doesn't propagate mid-session.
5. Grafana Cloud is connected to Claude Desktop via a service account token with the minimum required role (Viewer for read, Editor for write).
6. The service account is scoped per team or per environment — not a shared admin token.
7. MCP tool sets are audited and trimmed — write tools are scoped to platform engineers, read-only tools are available broadly.
