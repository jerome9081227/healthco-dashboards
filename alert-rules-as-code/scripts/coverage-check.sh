#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# coverage-check.sh — CI gate for alert coverage
# ---------------------------------------------------------------------------
# Supports two Terraform patterns:
#
#   for_each pattern (default):
#     alerts.tf uses `for_each = var.services`; services come from tfvars.
#     Coverage check = "is this service a key in terraform.tfvars services map?"
#
#   static pattern:
#     Per-service .tf files with literal annotation strings.
#     Coverage check = grep for service/signal literal annotations.
#
# The script auto-detects which pattern is in use.
# ---------------------------------------------------------------------------
set -euo pipefail

SERVICES_FILE="service-registry/services.txt"
TERRAFORM_DIR="terraform"
TFVARS_FILE="$TERRAFORM_DIR/terraform.tfvars"
SIGNALS=("latency" "traffic" "errors" "saturation")
FAIL=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Alert Coverage Gate"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ! -f "$SERVICES_FILE" ]; then
  echo "❌ $SERVICES_FILE not found"; exit 1
fi

TOTAL=$(grep -c '[^[:space:]]' "$SERVICES_FILE" || true)
echo ""
echo "Registered services: $TOTAL"

# ── Detect pattern ─────────────────────────────────────────────────────────
if grep -ql 'for_each\s*=\s*var\.services' "$TERRAFORM_DIR"/*.tf 2>/dev/null; then
  PATTERN="for_each"
  echo "Pattern detected: for_each (service registry → tfvars)"
else
  PATTERN="static"
  echo "Pattern detected: static (per-service annotation literals)"
fi
echo ""

mapfile -t ALL_SERVICES < <(grep -v '^[[:space:]]*$' "$SERVICES_FILE")

if [ "$PATTERN" = "for_each" ]; then

  if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ $TFVARS_FILE not found (required for for_each pattern)"; exit 1
  fi

  echo "[ Check 1 ] Service coverage (tfvars registry)"
  for SERVICE in "${ALL_SERVICES[@]}"; do
    if grep -qE "\"$SERVICE\"\s*=" "$TFVARS_FILE" 2>/dev/null; then
      echo "  ✅ $SERVICE"
    else
      echo "  ❌ $SERVICE — not found in $TFVARS_FILE services map"
      FAIL=1
    fi
  done

  echo ""
  echo "[ Check 2 ] Golden signal completeness (alerts.tf rule blocks)"
  ALERTS_FILE=$(find "$TERRAFORM_DIR" -name "alerts.tf" | head -1)
  if [ -z "$ALERTS_FILE" ]; then
    echo "  ❌ No alerts.tf found in $TERRAFORM_DIR/"
    FAIL=1
  else
    for SIGNAL in "${SIGNALS[@]}"; do
      if grep -q "\"signal\".*\"$SIGNAL\"" "$ALERTS_FILE" 2>/dev/null || \
         grep -q "signal.*=.*\"$SIGNAL\"" "$ALERTS_FILE" 2>/dev/null; then
        echo "  ✅ $SIGNAL rule defined"
      else
        echo "  ❌ $SIGNAL rule missing from $ALERTS_FILE"
        FAIL=1
      fi
    done
    RULE_BLOCKS=$(grep -c '^[[:space:]]*rule {' "$ALERTS_FILE" || true)
    echo "  ℹ️  $RULE_BLOCKS rule blocks defined (expect 4 × ${#ALL_SERVICES[@]} = $(( 4 * TOTAL )) total after apply)"
  fi

else

  echo "[ Check 1 ] Service coverage"
  COVERED_SERVICES=$(grep -rh '"service"' "$TERRAFORM_DIR"/ \
    | grep -oP '"service"\s*=\s*"\K[^"]+' | sort -u || true)

  for SERVICE in "${ALL_SERVICES[@]}"; do
    if echo "$COVERED_SERVICES" | grep -qx "$SERVICE"; then
      echo "  ✅ $SERVICE"
    else
      echo "  ❌ $SERVICE — no alert rules found"
      FAIL=1
    fi
  done

  echo ""
  echo "[ Check 2 ] Golden signal completeness"
  for SERVICE in "${ALL_SERVICES[@]}"; do
    for SIGNAL in "${SIGNALS[@]}"; do
      if grep -rl "\"signal\".*\"$SIGNAL\"" "$TERRAFORM_DIR"/ 2>/dev/null \
          | xargs grep -ql "\"service\".*\"$SERVICE\"" 2>/dev/null; then
        :
      else
        echo "  ❌ $SERVICE missing signal: $SIGNAL"
        FAIL=1
      fi
    done
  done
  [ "$FAIL" -eq 0 ] && echo "  ✅ All services have all four golden signals"

fi

# ── Check 3: semantic lint (non-testdata only) ─────────────────────────────
echo ""
echo "[ Check 3 ] Signal/query semantic check"
SEMANTIC_CHECKED=0

while IFS= read -r TF_FILE; do
  if grep -q "grafana-testdata-datasource" "$TF_FILE" 2>/dev/null; then
    continue
  fi
  SEMANTIC_CHECKED=1
  if grep -q '"signal".*"latency"' "$TF_FILE" || grep -q 'signal.*=.*"latency"' "$TF_FILE"; then
    if ! grep -qE '(histogram_quantile|_duration_|_latency)' "$TF_FILE"; then
      echo "  ❌ $TF_FILE: signal=latency but no histogram expression found"
      FAIL=1
    fi
  fi
  if grep -q '"signal".*"errors"' "$TF_FILE" || grep -q 'signal.*=.*"errors"' "$TF_FILE"; then
    if ! grep -qE '(status=~|error|5\.\.)'  "$TF_FILE"; then
      echo "  ❌ $TF_FILE: signal=errors but no status/error expression found"
      FAIL=1
    fi
  fi
done < <(find "$TERRAFORM_DIR" -name "*.tf" -type f)

if [ "$SEMANTIC_CHECKED" -eq 0 ]; then
  echo "  ⚠️  All files use testdata datasource — semantic check skipped"
  echo "      (swap datasource_uid to your Mimir UID to enable this check)"
else
  [ "$FAIL" -eq 0 ] && echo "  ✅ Semantic checks passed"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ "$FAIL" -eq 0 ]; then
  echo "  ✅ Coverage: $TOTAL/$TOTAL services | $(( TOTAL * 4 )) rules (after apply)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo "  ❌ Coverage gate FAILED — fix gaps before merging"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 1
fi
