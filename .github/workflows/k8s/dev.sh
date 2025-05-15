#!/bin/bash

# Load common functions and variables
source "$(dirname "$0")/common.sh"

# ECR configuration
AWS_ACCOUNT_ID="886093416603"
AWS_REGION="eu-central-1"
ECR_REPO="emcp"
IMAGE_TAG="dev"  # Use simple tag

echo "=== Deploying to DEVELOPMENT Environment ==="
NAMESPACE="emcp-dev"

# Ensure namespace exists
ensure_namespace "$NAMESPACE"

# Create AWS ECR pull secret
echo "Creating ECR pull credentials..."
TOKEN=$(aws ecr get-login-password --region ${AWS_REGION})
kubectl create secret docker-registry aws-ecr-creds \
  --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com \
  --docker-username=AWS \
  --docker-password="${TOKEN}" \
  --namespace=${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy Admin service from ECR
echo "Deploying Admin service from ECR..."
helm upgrade --install admin ./charts/admin \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --values ./charts/admin/environments/values.dev.yaml \
  --set image.repository="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}" \
  --set image.tag="${IMAGE_TAG}" \
  --set image.pullPolicy=Always \
  --set imagePullSecrets[0].name=aws-ecr-creds \
  --set environment=dev \
  --set logging.level=debug \
  --set logging.format=pretty \
  --timeout 10m \
  --wait

# Check deployment status
check_status "statefulset" "admin" "$NAMESPACE"

echo "=== DEV Deployment Complete ==="