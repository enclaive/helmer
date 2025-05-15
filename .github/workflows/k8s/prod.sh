#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to PRODUCTION Environment ==="
NAMESPACE="emcp-prod"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# Deploy Admin service
echo "Deploying Admin service..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/values.prod.yaml \
  --set image.tag="${ADMIN_TAG:-prod-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --set environment=production \
  --set logging.level=info \
  --set logging.format=json \
  --timeout 15m \
  --wait

# Check deployment status
check_status "statefulset" "admin" "$NAMESPACE"

echo "=== PRODUCTION Deployment Complete ==="