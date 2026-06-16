# k6 PR Gate Workflow Debrief — 2026-06-16

## 🎯 What I Can Tell Customers (Top 5–7 Insights)

- **k6 PR gate end-to-end** — "I personally built this from scratch — k6 test in VCS, GitHub Actions workflow, branch protection rule. When the threshold breaches, the merge button is physically blocked. I can walk your team through the exact setup."
- **Three credentials for Grafana Cloud k6, not one** — "Most teams get stuck here and think the integration is broken. You need the API token, the stack ID, and the project ID — all three before results stream. I hit every one of those errors so I know exactly where each credential lives."
- **`k6 run` vs `k6 cloud run` is a meaningful distinction** — "Local run keeps results in CI logs only — they're gone after 90 days and you can't trend across PRs. Cloud run gives every test a permanent URL in Grafana, which is how you catch regressions before they accumulate into incidents."
- **Branch protection is the actual enforcement layer** — "The Actions job failing alone doesn't block the merge. You have to go into branch settings and require the check as a status gate — it's two minutes but almost everyone skips it the first time."
- **Git-backed performance gates = compliance story** — "In healthcare or finops contexts, every merge having a linked k6 run in Grafana Cloud creates an immutable audit trail. That's not just DevOps hygiene — it's a direct answer to 'how do you prove nothing regressed before that change went to prod?'"
- **Mock server pattern for pipeline validation** — "You don't need a real service running to validate the full CI pipeline. A one-liner Python HTTP server lets you prove the wiring works end-to-end — then you swap in the real service startup when you're ready."

---

## 🏢 How Enterprise Does This at Scale

- A platform engineering team owns and publishes the threshold standards (`p95 < Xms`, `error rate < Y%`) as shared org-wide config; service teams inherit them and can only tighten, never loosen.
- At 500+ services, the mock server pattern gets replaced by ephemeral environments spun up per PR via Kubernetes namespaces or Docker Compose — the k6 script stays identical, only `TARGET_URL` changes via env var injection.
- Secrets (`K6_CLOUD_TOKEN`, `K6_CLOUD_STACK_ID`, `K6_CLOUD_PROJECT_ID`) are centralized in Vault or AWS Secrets Manager and injected via OIDC — not stored as individual repo secrets which become unmanageable at scale.
- Enterprises run the same k6 script at three stages: smoke (PR gate, 2 VUs / 30s), load (post-merge to staging, 50 VUs / 5m), and soak (weekly scheduled, 10 VUs / 1h) — differentiated by `options` objects, not separate scripts.
- In regulated industries, the Grafana Cloud k6 run URL attached to each merged PR becomes part of the change management record — directly answering HIPAA/SOC2 audit questions about what was validated before deployment.

---

## ⚡ 3-Arrow Cheat Sheet Entries

### Dev Productivity — k6 as GitHub PR Gate ★ signpost
> engineer opens a PR without knowing if their change degrades API performance → k6 smoke test runs in GitHub Actions against the service, threshold breaches fail the check → merge is physically blocked before code reaches staging — performance regressions get caught at the same gate as unit test failures, not in a post-incident retro

### De-risk Operations — Grafana Cloud k6 as CI Audit Trail
> every PR triggers a k6 cloud run streamed to Grafana Cloud → test results persist with a permanent URL per merge → compliance teams get a timestamped, linked performance record for every change — not just a green checkmark in Actions logs that expires in 90 days

### Dev Productivity — Three-Credential Pattern for k6 Cloud Auth
> team adds K6_CLOUD_TOKEN to CI and wonders why results don't appear in Grafana → stack ID and project ID are also required env vars → k6 cloud run streams to the right Grafana Cloud project with zero additional config — Datadog doesn't give you this level of native CI-to-observability linkage

---

## 💬 Discovery & Objection Handling

### Discovery Questions
- "Do your engineers know today if a code change degrades API performance before it merges — or does that surface in production?"
- "Where do your load test results live after a CI run? Are you able to trend p95 latency across PRs over time, or does it disappear with each run?"
- "If a regressing change makes it to staging, what's your current process for tracing it back to the PR that introduced it?"
- "Are your performance thresholds tied to your actual SLOs, or are they arbitrary numbers someone set up years ago?"

### Objection Handles
- **"We already have load testing in CI"** → "Are the results in Grafana alongside your live metrics, and is the merge button actually blocked when thresholds breach? Most teams have tests running but no enforcement and no trend history — those are the two things that matter."
- **"The three-credential setup sounds complex"** → "I hit all three errors myself in a single session. Once you know token + stack ID + project ID are all required, it's a 10-minute setup. The docs lead with just the token which is why everyone gets stuck."

---

## 📋 Reference Summary (What Good Looks Like)

1. k6 test file lives in VCS alongside the service it tests, with thresholds derived from the team's SLO definition.
2. GitHub Actions workflow triggers on every PR to `main` and runs `k6 cloud run` (not `k6 run`) against a staging or ephemeral environment.
3. Branch protection rule on `main` requires the k6 check to pass — the merge button is physically blocked, not just flagged.
4. Three secrets are configured and named correctly: `K6_CLOUD_TOKEN`, `K6_CLOUD_STACK_ID`, `K6_CLOUD_PROJECT_ID`.
5. Every CI test result has a permanent URL in Grafana Cloud k6, creating a linked audit trail per merge.
6. Thresholds match what's defined in the team's Grafana SLO — same error rate budget, same latency red line from the dashboard.
7. k6 results in Grafana Cloud trend across PRs, making performance regressions visible before they accumulate into incidents.
