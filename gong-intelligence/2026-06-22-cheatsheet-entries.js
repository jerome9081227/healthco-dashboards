// Grafana 3-Arrow Cheat Sheet Entries — Week of June 22, 2026
// Generated from Gong Intelligence Scan (Jun 15–22)
// Paste into cheatsheet.js entries array

const weeklyEntries = [

  // ─── CALL FLOW (Objections & Competitive) ───────────────────────────────

  {
    name: "Datadog Migration Is Too Painful",
    tag: "callflow",
    tagLabel: "Call Flow",
    steps: [
      "When a prospect says migration effort is the reason they're staying on Datadog → ask: 'Are there metrics you've had to rate-limit or stop sending to control costs?'",
      "Grafana's automated Datadog migration tool converts 90% of alerts and dashboards — and a dedicated Observability Architect is included free to handle the rest",
      "Hutch Games, Flink, and USDA all named migration as the blocker — then learned the automated tooling exists — that's the number that unblocks the conversation"
    ]
  },

  {
    name: "Datadog Rate-Limiting Blind Spots",
    tag: "callflow",
    tagLabel: "Call Flow",
    steps: [
      "When your champion says 'we manage Datadog costs by rate-limiting some metrics' → flag it: they've built deliberate blind spots into their own observability",
      "Grafana Cloud doesn't charge for custom metrics — a metric is a metric — plus Adaptive Telemetry identifies unused data and drops it automatically (30–50% cost reduction without losing signal)",
      "Hutch Games said rate-limiting caused 'internal headaches diagnosing issues and slower resolution of customer-facing problems' — that's the incident your CFO hears about"
    ]
  },

  {
    name: "Datadog Vendor Lock-In 12-Month Signal",
    tag: "callflow",
    tagLabel: "Call Flow",
    steps: [
      "When you see a prospect renewed Datadog for only 12 months → that's not a renewal, that's an evaluation window they deliberately created",
      "Flink renewed for 12 months through April 2027 specifically to avoid multi-year lock-in while they assess alternatives — they gave Grafana a look because of open standards (OTel) and migration tooling",
      "A 12-month Datadog contract is an open invitation — ask when it expires, put a follow-up in the calendar, and get the migration tool into their hands now"
    ]
  },

  {
    name: "Internal Grafana Instance vs. Grafana Cloud",
    tag: "callflow",
    tagLabel: "Call Flow",
    steps: [
      "When a prospect says Grafana 'doesn't work well' for logs or alerting → ask if they're using a shared internal instance or Grafana Cloud",
      "Shared enterprise instances often have admin-imposed limits (Loki capped at 1,000 log lines, alerting misconfigurations) — these are configuration decisions, not product limitations",
      "CIBC's team ranked Grafana third below Splunk and Dynatrace — not because of the product, but because of how their internal instance was configured. Grafana Cloud removes those artificial ceilings"
    ]
  },

  {
    name: "Honeycomb Wide Events Gap",
    tag: "callflow",
    tagLabel: "Call Flow",
    steps: [
      "When a prospect mentions wide events or ad-hoc high-cardinality analysis as a requirement → ask what their ingestion volume looks like and how often they query ad-hoc",
      "Grafana Explore Logs handles high-cardinality log data with schema-on-read querying, while Grafana Cloud's cost model (Adaptive Telemetry) prevents the cost explosion that wide-event storage typically creates",
      "Roche DHP is evaluating Honeycomb for wide events — but Honeycomb's cost at Roche scale would be prohibitive. Grafana's open-standards approach keeps that data accessible without the lock-in tax"
    ]
  },

  {
    name: "Incident.io OnCall vs. Grafana IRM",
    tag: "callflow",
    tagLabel: "Call Flow",
    steps: [
      "When a prospect is using Datadog for monitoring but Incident.io (or PagerDuty) for OnCall → they've already rejected Datadog's tightly bundled approach",
      "Grafana IRM integrates natively with Grafana's alerting stack — one tool for detection, correlation, and response, without paying for a separate OnCall product",
      "Flink uses Incident.io specifically because they find Datadog OnCall insufficient — they're already thinking in unbundled pieces. Grafana's open platform is the natural home for that thinking"
    ]
  },

  // ─── AI-FIRST (Emerging Use Cases) ──────────────────────────────────────

  {
    name: "AI Agent Token Cost Monitoring",
    tag: "ai-first",
    tagLabel: "AI-First",
    steps: [
      "When a prospect is building with LLMs or AI agents and asks how to track token spend or catch rogue agents → that's an AI observability entry point, not a standard infra pitch",
      "Grafana AI provides an application-layer library that generates LLM usage metrics — token consumption, request latency, model cost — surfaced in Grafana dashboards with anomaly alerting when an agent starts overconsumming",
      "fabric Inc. is using AWS Bedrock + LightLLM as a proxy — they need exactly this. Their first ask was 'how do I catch a rogue agent before it burns through budget?' Grafana AI answers that question out of the box"
    ]
  },

  {
    name: "AI Observability PII Guardrails",
    tag: "ai-first",
    tagLabel: "AI-First",
    steps: [
      "When a fintech or healthcare prospect asks whether Grafana AI Observability can detect sensitive data being sent to LLMs → this is a guardrails question, not a metrics question",
      "Grafana AI includes built-in guardrails that evaluate and redact PII, API keys, and email addresses in LLM prompts before they reach the model — observable and auditable",
      "Kuda's engineering lead asked this directly on a call this week — it's becoming a standard fintech AI security question. The answer is yes, and it's in the product today"
    ]
  },

  {
    name: "AI-Accelerated Shipping Needs Safe Release Infrastructure",
    tag: "ai-first",
    tagLabel: "AI-First",
    steps: [
      "When a prospect says they're using AI coding tools to ship faster → ask: 'How are you making sure faster shipping doesn't mean more incidents?'",
      "Grafana's DORA metric dashboards, deployment annotations, k6 pre-production load testing, and SLO tracking give engineering teams the confidence signal they need to release at AI speed",
      "The Gym Group put it plainly: 'To fully leverage AI investments for faster code generation, we need to safely release at higher frequency.' Grafana is the release confidence layer that makes AI-generated code production-safe"
    ]
  },

  {
    name: "BI Tool Displacement — Tableau to Grafana",
    tag: "ai-first",
    tagLabel: "AI-First",
    steps: [
      "When a prospect uses a BI tool (Tableau, Power BI) for incident reporting or operational dashboards → ask how they handle live incident investigation when a snapshot is 24 hours old",
      "Grafana connects directly to BigQuery, Google Cloud Logs, and live datasources — no snapshot delay — and AI-assisted dashboard creation (Claude + gcx CLI) cuts migration effort dramatically",
      "Home Depot is migrating 20 Tableau incident dashboards to Grafana by year-end. Their driver: 'Tableau's slow refresh rates are insufficient for live investigation.' Their accelerant: Claude writing Grafana dashboard code"
    ]
  },

  // ─── VERTICALS (Proof Points & Vertical Stories) ────────────────────────

  {
    name: "Property Finder: 50% Cost Cut + More Data",
    tag: "verticals",
    tagLabel: "Verticals",
    steps: [
      "When a prospect asks if they'll have to sacrifice data coverage to reduce Datadog costs → tell them Property Finder did the opposite",
      "Property Finder migrated from Datadog to Grafana Cloud, reduced costs by over 50%, and simultaneously *increased* log and trace retention",
      "That's the number that stops the CFO conversation: you pay less, and you see more — not a trade-off, an upgrade"
    ]
  },

  {
    name: "Kuda: MTTR Halved on Grafana",
    tag: "verticals",
    tagLabel: "Verticals",
    steps: [
      "When a fintech prospect asks what operational improvement they can expect after switching from Datadog → use Kuda as your anchor",
      "Kuda migrated from Datadog (spending $33K/month) to Grafana Cloud, with a dedicated Observability Architect included free — and reduced MTTR by 50%",
      "Half the mean time to resolve means half the customer-facing outage window. For a digital bank, that's the metric that ends the evaluation"
    ]
  },

  {
    name: "MIT OpenLearning: Adaptive Logging at Scale",
    tag: "verticals",
    tagLabel: "Verticals",
    steps: [
      "When a prospect running Kubernetes at scale asks how to control log costs without losing visibility → lead with adaptive logging",
      "MIT Open Learning replaced a fragmented stack (New Relic, Datadog, AWS CloudWatch, Fluentd) with Grafana Cloud, and achieved immediate cost and noise reduction via adaptive logging — high-volume, low-signal logs dropped without losing critical data",
      "Their goal is 1 billion learners. Grafana is the observability foundation for that scale. If it works for MIT at hypergrowth, it works for your platform team"
    ]
  },

  {
    name: "Federal Datadog Displacement — Sept 30 Deadline",
    tag: "verticals",
    tagLabel: "Verticals",
    steps: [
      "When engaging a federal agency with a Datadog renewal approaching → ask when their contract expires and whether they've evaluated total cost of ownership against Grafana",
      "USDA is replacing Datadog by September 30, with potential quarterly incentive discounts for federal clients who contract by July 30; Grafana supports E-auth SSO, SNMP traps, VMware, and mainframe integrations out of the box",
      "A 26-year monitoring veteran at USDA said Grafana Cloud is the right replacement — that's the peer validation federal agencies want to hear before they sign"
    ]
  },

  {
    name: "Roche: Platform Observability with Chargeback",
    tag: "verticals",
    tagLabel: "Verticals",
    steps: [
      "When a large enterprise prospect has multiple business units each managing their own observability tooling → ask if they have a chargeback model for platform costs",
      "Roche's Digital Health Platforms team is building a unified observability platform with chargeback to individual product teams — using Grafana's four observability pillars: business insights, reliability, security, and FinOps",
      "Platform engineering teams buying Grafana as infrastructure for other teams to use — that's a multiplier deal, not a point solution sale"
    ]
  },

];

module.exports = weeklyEntries;
