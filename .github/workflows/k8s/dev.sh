#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to DEVELOPMENT Environment ==="
NAMESPACE="emcp-dev"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# Deploy Backend service with extended timeout
echo "Deploying Backend service..."
helm upgrade --install backend ./charts/backend \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/backend/environments/dev.yaml \
  --set image.tag="${BACKEND_TAG:-dev-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --set environment=dev \
  --set logging.level=debug \
  --set features.enableBackups=false \
  --set persistence.storageClass=gp2 \
  --timeout 10m \
  --wait \
  --debug

# Check deployment status
check_status "statefulset" "backend" "$NAMESPACE"

# Deploy Frontend service
echo "Deploying Frontend service..."
helm upgrade --install frontend ./charts/frontend \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/frontend/environments/dev.yaml \
  --set image.tag="${FRONTEND_TAG:-dev-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --set environment=dev \
  --set api.url="https://emcp-dev.enclaive.cloud" \
  --set app.url="https://dev.console.enclaive.cloud" \
  --set features.enableBetaFeatures=true \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "frontend" "$NAMESPACE"

# Deploy Admin service
echo "Deploying Admin service..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/dev.yaml \
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