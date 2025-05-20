#!/bin/bash
# Script to copy multiple images from Harbor to ECR

set -e  # Exit on error

# Configuration variables
HARBOR_REGISTRY="harbor.enclaive.cloud"
HARBOR_REPO="emcp/admin"
HARBOR_TAG="dev"  # Use the simple tag that exists
HARBOR_USERNAME="itzhak"  # Replace with your actual Harbor username
HARBOR_PASSWORD='cksdl)(Kcjdksdf=98sd8"njkds)'
AWS_REGION="eu-central-1"
AWS_ACCOUNT_ID="886093416603"

# Services to migrate (add or remove as needed)
declare -a SERVICES=(
  "emcp/kc-provider"
)

echo "===== COPYING IMAGES FROM HARBOR TO ECR ====="

# Step 1: Login to Harbor
echo "Logging in to Harbor..."
echo "${HARBOR_PASSWORD}" | docker login "${HARBOR_REGISTRY}" -u "${HARBOR_USERNAME}" --password-stdin

# Step 2: Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Process each service
for SERVICE in "${SERVICES[@]}"; do
  # Extract repository and tag from service
  REPO=$(echo $SERVICE | cut -d: -f1)
  TAG=$(echo $SERVICE | cut -d: -f2)
  
  # Extract repository name without namespace
  REPO_NAME=$(echo $REPO | cut -d/ -f2)
  
  echo ""
  echo "Processing service: ${REPO_NAME}:${TAG}"
  
  # Full image references
  HARBOR_IMAGE="${HARBOR_REGISTRY}/${REPO}:${TAG}"
  ECR_REPO="${REPO_NAME}"
  ECR_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${TAG}"
  
  echo "Source image: ${HARBOR_IMAGE}"
  echo "Target image: ${ECR_IMAGE}"
  
  # Create ECR repository if it doesn't exist
  echo "Creating ECR repository ${ECR_REPO} if it doesn't exist..."
  aws ecr describe-repositories --repository-names "${ECR_REPO}" --region "${AWS_REGION}" 2>/dev/null || \
      aws ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}"
  
  # Pull the image from Harbor
  echo "Pulling image from Harbor..."
  docker pull "${HARBOR_IMAGE}"
  
  # Tag the image for ECR
  echo "Tagging image for ECR..."
  docker tag "${HARBOR_IMAGE}" "${ECR_IMAGE}"
  
  # Push to ECR
  echo "Pushing image to ECR..."
  docker push "${ECR_IMAGE}"
  
  echo "✅ Successfully copied ${HARBOR_IMAGE} to ${ECR_IMAGE}"
done

echo ""
echo "===== ALL IMAGES SUCCESSFULLY COPIED TO ECR ====="
echo "The following images are now available in ECR:"
for SERVICE in "${SERVICES[@]}"; do
  REPO=$(echo $SERVICE | cut -d: -f1)
  TAG=$(echo $SERVICE | cut -d: -f2)
  REPO_NAME=$(echo $REPO | cut -d/ -f2)
  echo "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${TAG}"
done