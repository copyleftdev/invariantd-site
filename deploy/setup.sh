#!/usr/bin/env bash
set -euo pipefail

# ── invariantd.com — DigitalOcean deployment via doctl ───
#
# Creates a $4/mo droplet, provisions it, and deploys the dashboard.
# Requires: doctl authenticated, SSH key registered with DO.
#
# Usage:
#   bash deploy/setup.sh          # Create droplet + deploy
#   bash deploy/setup.sh teardown # Destroy droplet

DROPLET_NAME="invariantd-web"
REGION="nyc1"
SIZE="s-1vcpu-512mb-10gb"   # $4/mo
IMAGE="ubuntu-22-04-x64"
DEPLOY_DIR="/opt/invariantd"
DOMAIN="invariantd.com"

# ── Teardown ─────────────────────────────────────
if [[ "${1:-}" == "teardown" ]]; then
  echo "Destroying droplet $DROPLET_NAME..."
  doctl compute droplet delete "$DROPLET_NAME" --force 2>/dev/null || true
  echo "Removing DNS A record..."
  RECORD_ID=$(doctl compute domain records list "$DOMAIN" --format ID,Type,Name --no-header 2>/dev/null | awk '$2=="A" && $3=="@" {print $1}')
  if [[ -n "$RECORD_ID" ]]; then
    doctl compute domain records delete "$DOMAIN" "$RECORD_ID" --force
  fi
  echo "Done."
  exit 0
fi

# ── Get SSH key ──────────────────────────────────
echo "── invariantd.com deployment ──"
echo ""

SSH_KEY_ID=$(doctl compute ssh-key list --format ID --no-header | head -1)
if [[ -z "$SSH_KEY_ID" ]]; then
  echo "ERROR: No SSH keys registered with DigitalOcean."
  echo "Run: doctl compute ssh-key import my-key --public-key-file ~/.ssh/id_ed25519.pub"
  exit 1
fi
echo "Using SSH key: $SSH_KEY_ID"

# ── Check if droplet exists ──────────────────────
EXISTING_IP=$(doctl compute droplet list --format Name,PublicIPv4 --no-header 2>/dev/null | awk -v n="$DROPLET_NAME" '$1==n {print $2}')

if [[ -n "$EXISTING_IP" ]]; then
  echo "Droplet already exists at $EXISTING_IP"
  DROPLET_IP="$EXISTING_IP"
else
  # ── Create droplet ─────────────────────────────
  echo "Creating droplet: $DROPLET_NAME ($SIZE in $REGION)..."
  doctl compute droplet create "$DROPLET_NAME" \
    --region "$REGION" \
    --size "$SIZE" \
    --image "$IMAGE" \
    --ssh-keys "$SSH_KEY_ID" \
    --tag-name "invariantd" \
    --wait

  # Get IP
  echo "Waiting for IP assignment..."
  sleep 5
  DROPLET_IP=$(doctl compute droplet list --format Name,PublicIPv4 --no-header | awk -v n="$DROPLET_NAME" '$1==n {print $2}')

  if [[ -z "$DROPLET_IP" ]]; then
    echo "ERROR: Could not get droplet IP"
    exit 1
  fi

  echo "Droplet IP: $DROPLET_IP"

  # ── Set DNS A record ───────────────────────────
  echo "Setting DNS A record: $DOMAIN → $DROPLET_IP"
  # Remove existing A record for @ if any
  OLD_RECORD=$(doctl compute domain records list "$DOMAIN" --format ID,Type,Name --no-header 2>/dev/null | awk '$2=="A" && $3=="@" {print $1}')
  if [[ -n "$OLD_RECORD" ]]; then
    doctl compute domain records delete "$DOMAIN" "$OLD_RECORD" --force
  fi
  doctl compute domain records create "$DOMAIN" \
    --record-type A \
    --record-name "@" \
    --record-data "$DROPLET_IP" \
    --record-ttl 300

  # Wait for SSH
  echo "Waiting for SSH to become available..."
  for i in $(seq 1 30); do
    if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "root@${DROPLET_IP}" "true" 2>/dev/null; then
      break
    fi
    sleep 5
  done
fi

echo ""
echo "── Provisioning $DROPLET_IP ──"

# ── Provision: install Docker + deploy ───────────
ssh -o StrictHostKeyChecking=no "root@${DROPLET_IP}" bash -s <<'REMOTE'
set -euo pipefail

# Install Docker
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable --now docker
fi

# Install Docker Compose plugin
if ! docker compose version &>/dev/null; then
  apt-get update -qq && apt-get install -y -qq docker-compose-plugin
fi

# Create directories
mkdir -p /opt/invariantd/dashboard /opt/invariantd/logs
echo "Provisioning complete."
REMOTE

# ── Copy files ───────────────────────────────────
echo "Syncing dashboard files..."
rsync -azq --delete site/ "root@${DROPLET_IP}:${DEPLOY_DIR}/dashboard/"

echo "Syncing deploy configs..."
rsync -azq deploy/Caddyfile deploy/Dockerfile deploy/docker-compose.yml "root@${DROPLET_IP}:${DEPLOY_DIR}/"

# ── Build and start ──────────────────────────────
echo "Building and starting container..."
ssh "root@${DROPLET_IP}" "cd ${DEPLOY_DIR} && docker compose build --quiet && docker compose up -d"

echo ""
echo "══════════════════════════════════════════"
echo "  invariantd.com deployed successfully"
echo "══════════════════════════════════════════"
echo ""
echo "  URL:       https://$DOMAIN"
echo "  IP:        $DROPLET_IP"
echo "  Droplet:   $DROPLET_NAME ($SIZE)"
echo "  Region:    $REGION"
echo "  Cost:      ~\$4/mo"
echo ""
echo "  TLS:       Auto-provisioned by Caddy (Let's Encrypt)"
echo "  Logs:      ssh root@$DROPLET_IP 'tail -f $DEPLOY_DIR/logs/access.log'"
echo "  Update:    bash deploy/update.sh $DROPLET_IP"
echo "  Teardown:  bash deploy/setup.sh teardown"
echo ""
