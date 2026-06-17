#!/usr/bin/env python3
"""
coverage-report.py — Compute and display alert coverage gap analysis.

Supports two Terraform patterns:
  for_each: services defined in terraform.tfvars services map (recommended)
  static:   per-service .tf files with literal annotation strings

Run from the repo root:
  python3 scripts/coverage-report.py
  python3 scripts/coverage-report.py --json    # machine-readable output
"""
import argparse
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

SIGNALS = ["latency", "traffic", "errors", "saturation"]
SERVICES_FILE = Path("service-registry/services.txt")
TERRAFORM_DIR = Path("terraform")
TFVARS_FILE   = TERRAFORM_DIR / "terraform.tfvars"


def get_registered_services() -> list[str]:
    if not SERVICES_FILE.exists():
        print(f"ERROR: {SERVICES_FILE} not found", file=sys.stderr)
        sys.exit(1)
    return [s.strip() for s in SERVICES_FILE.read_text().splitlines() if s.strip()]


def detect_pattern() -> str:
    for tf_file in TERRAFORM_DIR.rglob("*.tf"):
        if re.search(r'for_each\s*=\s*var\.services', tf_file.read_text()):
            return "for_each"
    return "static"


def get_coverage_for_each(registered: list[str]) -> dict[str, set[str]]:
    if not TFVARS_FILE.exists():
        print(f"ERROR: {TFVARS_FILE} not found", file=sys.stderr)
        sys.exit(1)

    tfvars_content = TFVARS_FILE.read_text()

    signals_defined = set()
    alerts_file = TERRAFORM_DIR / "alerts.tf"
    if alerts_file.exists():
        alerts_content = alerts_file.read_text()
        for signal in SIGNALS:
            if re.search(rf'signal\s*=\s*"{signal}"', alerts_content):
                signals_defined.add(signal)

    coverage: dict[str, set[str]] = {}
    for service in registered:
        if re.search(rf'"{re.escape(service)}"\s*=\s*\{{', tfvars_content):
            coverage[service] = signals_defined
        else:
            coverage[service] = set()

    return coverage


def get_coverage_static() -> dict[str, set[str]]:
    coverage: dict[str, set[str]] = defaultdict(set)

    for tf_file in TERRAFORM_DIR.rglob("*.tf"):
        content = tf_file.read_text()
        annotation_blocks = re.findall(r'annotations\s*=\s*\{([^}]+)\}', content, re.DOTALL)
        for block in annotation_blocks:
            service_match = re.search(r'service\s*=\s*"([^"]+)"', block)
            signal_match  = re.search(r'signal\s*=\s*"([^"]+)"', block)
            if service_match and signal_match:
                service = service_match.group(1)
                signal  = signal_match.group(1)
                if signal in SIGNALS:
                    coverage[service].add(signal)

    return dict(coverage)


def render_report(registered: list[str], coverage: dict[str, set[str]], pattern: str, as_json: bool):
    full_coverage    = []
    partial_coverage = []
    no_coverage      = []

    for service in registered:
        covered = coverage.get(service, set())
        missing = set(SIGNALS) - covered
        if not missing:
            full_coverage.append(service)
        elif covered:
            partial_coverage.append({
                "service": service,
                "covered": sorted(covered),
                "missing": sorted(missing),
            })
        else:
            no_coverage.append(service)

    total = len(registered)
    pct   = int(100 * len(full_coverage) / total) if total else 0

    if as_json:
        print(json.dumps({
            "total_services":       total,
            "full_coverage_count":  len(full_coverage),
            "coverage_percent":     pct,
            "pattern":              pattern,
            "full_coverage":        sorted(full_coverage),
            "partial_coverage":     partial_coverage,
            "no_coverage":          sorted(no_coverage),
        }, indent=2))
        return

    bar_filled = int(pct / 5)
    bar = "█" * bar_filled + "░" * (20 - bar_filled)
    print(f"\n{'━'*58}")
    print(f"  Alert Coverage Report  [{pattern} pattern]")
    print(f"{'━'*58}")
    print(f"  [{bar}] {pct}%  ({len(full_coverage)}/{total} services)")
    print()

    if full_coverage:
        print(f"  ✅ Full coverage ({len(full_coverage)} services)")
        for s in sorted(full_coverage):
            print(f"     {s}")
        print()

    if partial_coverage:
        print(f"  ⚠️  Partial coverage ({len(partial_coverage)} services)")
        for entry in partial_coverage:
            print(f"     {entry['service']}")
            print(f"       covered : {', '.join(entry['covered'])}")
            print(f"       missing : {', '.join(entry['missing'])}")
        print()

    if no_coverage:
        print(f"  ❌ No coverage ({len(no_coverage)} services)")
        for s in sorted(no_coverage):
            print(f"     {s}")
        print()

    print(f"{'━'*58}")
    if no_coverage or partial_coverage:
        if pattern == "for_each":
            print(f"  ACTION: Add missing services to terraform/terraform.tfvars")
            print(f"  RUN:    python3 scripts/sync-from-catalog.py  # sync from Service Catalog")
        else:
            print(f"  ACTION: Add alert rule files to terraform/ for uncovered services")
        sys.exit(1)
    else:
        print(f"  All {total} services have full golden signal coverage 🎉")
        print(f"  Total alert rules after apply: {total * 4}")
    print(f"{'━'*58}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Alert coverage gap analysis")
    parser.add_argument("--json", action="store_true", help="Output JSON instead of human-readable")
    args = parser.parse_args()

    registered = get_registered_services()
    pattern    = detect_pattern()

    if pattern == "for_each":
        coverage = get_coverage_for_each(registered)
    else:
        coverage = get_coverage_static()

    render_report(registered, coverage, pattern, as_json=args.json)
