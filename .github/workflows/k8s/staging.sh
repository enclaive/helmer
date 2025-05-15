#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to STAGING Environment ==="
NAMESPACE="emcp-staging"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# Deploy Admin service
echo "Deploying Admin service..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/staging.yaml \
  --set image.tag="${ADMIN_TAG:-staging-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --set environment=staging \
  --set logging.level=info \
  --set logging.format=json \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "admin" "$NAMESPACE"

echo "=== STAGING Deployment Complete ==="