#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to DEV Environment ==="
NAMESPACE="emcp-dev"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# MongoDB deployment with extended timeout
echo "Deploying MongoDB..."
helm upgrade --install mongodb ./charts/mongodb \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/mongodb/environments/dev.yaml \
  --set image.tag="${MONGODB_TAG:-5.0.2}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --timeout 15m \
  --wait \
  --debug

# Check deployment status
check_status "statefulset" "mongodb" "$NAMESPACE"

# Redis deployment
echo "Deploying Redis..."
helm upgrade --install redis ./charts/redis \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/redis/environments/dev.yaml \
  --set image.tag="${REDIS_TAG:-6.2-alpine}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "redis" "$NAMESPACE"

# Admin deployment
echo "Deploying Admin..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/dev.yaml \
  --set image.tag="${ADMIN_TAG:-dev-latest}" \
  --set imagePullSecrets[0].name=harbor-creds \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "admin" "$NAMESPACE"

echo "=== DEV Deployment Complete ==="