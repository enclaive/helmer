#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

echo "=== Deploying to DEVELOPMENT Environment ==="
NAMESPACE="emcp-deve"

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
  --set redis.config.maxmemory="128mb" \
  --set redis.config.maxmemory-policy="allkeys-lru" \
  --set redis.config.appendonly="yes" \
  --set redis.config.appendfsync="everysec" \
  --set persistence.enabled=true \
  --set persistence.storageClass="gp3" \
  --set persistence.size="512Mi" \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "redis" "$NAMESPACE"

# Deploy Admin service
echo "Deploying Admin service..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/values.dev.yaml \
  --set image.repository="886093416603.dkr.ecr.eu-central-1.amazonaws.com/admin" \
  --set image.tag="dev" \
  --set image.pullPolicy=Always \
  --set imagePullSecrets[0].name=aws-ecr-creds \
  --set environment=dev \
  --set logging.level=debug \
  --set logging.format=pretty \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "admin" "$NAMESPACE"

# Deploy Backend service
echo "Deploying Backend service..."
helm upgrade --install backend ./charts/backend \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/backend/environments/values.dev.yaml \
  --set image.repository="886093416603.dkr.ecr.eu-central-1.amazonaws.com/backend0" \
  --set image.tag="dev" \
  --set image.pullPolicy=Always \
  --set imagePullSecrets[0].name=aws-ecr-creds \
  --set environment=dev \
  --set logging.level=debug \
  --set logging.format=pretty \
  --set features.enableBackups=false \
  --set mongodb.host=mongodb \
  --set mongodb.port=27017 \
  --set mongodb.database=backend_db \
  --set mongodb.username=root \
  --set mongodb.password=root \
  --set redis.host=redis \
  --set redis.port=6379 \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "backend" "$NAMESPACE"

echo "=== DEV Deployment Complete ==="