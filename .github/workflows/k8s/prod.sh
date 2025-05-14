#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to PRODUCTION Environment ==="
NAMESPACE="emcp-prod"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# Deploy Backend service with extended timeout
echo "Deploying Backend service..."
helm upgrade --install backend ./charts/backend \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/backend/environments/prod.yaml \
  --set image.tag="${BACKEND_TAG:-prod-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --set environment=production \
  --set logging.level=info \
  --set features.enableBackups=true \
  --timeout 15m \
  --wait \
  --debug

# Check deployment status
check_status "statefulset" "backend" "$NAMESPACE"

# Deploy Frontend service
echo "Deploying Frontend service..."
helm upgrade --install frontend ./charts/frontend \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/frontend/environments/prod.yaml \
  --set image.tag="${FRONTEND_TAG:-prod-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --set environment=production \
  --set api.url="https://emcp-prod.enclaive.cloud" \
  --set app.url="https://console.enclaive.cloud" \
  --set features.enableBetaFeatures=false \
  --timeout 15m \
  --wait

# Check deployment status
check_status "statefulset" "frontend" "$NAMESPACE"

# Deploy Admin service
echo "Deploying Admin service..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/prod.yaml \
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