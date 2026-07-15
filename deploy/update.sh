#!/usr/bin/env bash
set -euo pipefail

# ── Quick update: push dashboard changes to live site ──
#
# Usage:
#   bash deploy/update.sh              # auto-detect droplet IP via doctl
#   bash deploy/update.sh 167.99.1.2   # or specify IP directly

DROPLET_NAME="invariantd-web"
DEPLOY_DIR="/opt/invariantd"

if [[ -n "${1:-}" ]]; then
  DROPLET_IP="$1"
else
  DROPLET_IP=$(doctl compute droplet list --format Name,PublicIPv4 --no-header | awk -v n="$DROPLET_NAME" '$1==n {print $2}')
  if [[ -z "$DROPLET_IP" ]]; then
    echo "ERROR: Droplet $DROPLET_NAME not found. Run deploy/setup.sh first."
    exit 1
  fi
fi

echo "── Deploying to $DROPLET_IP ──"

echo "Syncing dashboard..."
rsync -azq --delete site/ "root@${DROPLET_IP}:${DEPLOY_DIR}/dashboard/"

echo "Syncing configs..."
rsync -azq deploy/Caddyfile deploy/Dockerfile deploy/docker-compose.yml "root@${DROPLET_IP}:${DEPLOY_DIR}/"

echo "Rebuilding..."
ssh "root@${DROPLET_IP}" "cd ${DEPLOY_DIR} && docker compose build --quiet && docker compose up -d"

echo "── Live: https://invariantd.com ──"
