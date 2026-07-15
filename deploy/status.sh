#!/usr/bin/env bash
set -euo pipefail

# ── Check deployment status via doctl ──

DROPLET_NAME="invariantd-web"

echo "── invariantd.com status ──"
echo ""

# Droplet info
doctl compute droplet list --format Name,PublicIPv4,Region,Size,Status,Memory,VCPUs --no-header | grep "$DROPLET_NAME" || echo "Droplet not found."

echo ""

# DNS records
echo "DNS records for invariantd.com:"
doctl compute domain records list invariantd.com --format Type,Name,Data,TTL --no-header 2>/dev/null || echo "Domain not configured in DO."

echo ""

# Quick HTTP check
DROPLET_IP=$(doctl compute droplet list --format Name,PublicIPv4 --no-header 2>/dev/null | awk -v n="$DROPLET_NAME" '$1==n {print $2}')
if [[ -n "$DROPLET_IP" ]]; then
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://invariantd.com" 2>/dev/null || echo "000")
  if [[ "$HTTP_STATUS" == "200" ]]; then
    echo "HTTPS: ✓ https://invariantd.com (200 OK)"
  else
    echo "HTTPS: ✗ https://invariantd.com (status: $HTTP_STATUS)"
  fi
fi
