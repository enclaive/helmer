#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to DEVELOPMENT Environment ==="
NAMESPACE="emcp-dev"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# Deploy Admin service
echo "Deploying Admin service..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/values.dev.yaml \
  --set image.tag="${ADMIN_TAG:-dev-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --set environment=dev \
  --set logging.level=debug \
  --set logging.format=pretty \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "admin" "$NAMESPACE"

echo "=== DEV Deployment Complete ==="