#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to DEVELOPMENT Environment ==="
NAMESPACE="emcp-dev"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# Create AWS ECR pull secret
echo "Creating ECR pull credentials..."
TOKEN=$(aws ecr get-login-password --region eu-central-1)
kubectl create secret docker-registry aws-ecr-creds \
  --docker-server=886093416603.dkr.ecr.eu-central-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="${TOKEN}" \
  --namespace=${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy Redis service
echo "Deploying Redis service..."
helm upgrade --install redis ./charts/redis \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/redis/environments/values.dev.yaml \
  --set image.repository="redis" \
  --set image.tag="6.2-alpine" \
  --set image.pullPolicy=Always \
  --set service.type=ClusterIP \
  --set service.port=6379 \
  --set service.targetPort=6379 \
  --set redis.port=6379 \
  --set redis.config.maxmemory="128mb" \
  --set redis.config.maxmemory-policy="allkeys-lru" \
  --set redis.config.appendonly="yes" \
  --set redis.config.appendfsync="everysec" \
  --set persistence.enabled=true \
  --set persistence.storageClass="openebs-hostpath" \
  --set persistence.size="512Mi" \
  --timeout 5m \
  --wait


echo "=== DEV Deployment Complete ==="