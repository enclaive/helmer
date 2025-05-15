#!/bin/bash
# Script to copy an image from Harbor to ECR

set -e  # Exit on error

# Configuration variables
HARBOR_REGISTRY="harbor.enclaive.cloud"
HARBOR_REPO="emcp/admin"
HARBOR_TAG="dev"  # Use the simple tag that exists
HARBOR_USERNAME="itzhak"  # Replace with your actual Harbor username
HARBOR_PASSWORD='cksdl)(Kcjdksdf=98sd8"njkds)'

AWS_REGION="eu-central-1"  # Replace with your AWS region
AWS_ACCOUNT_ID="886093416603"  # Replace with your AWS account ID
ECR_REPO="emcp"  # The name of your ECR repository

# Full image references
HARBOR_IMAGE="${HARBOR_REGISTRY}/${HARBOR_REPO}:${HARBOR_TAG}"
ECR_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${HARBOR_TAG}"

echo "===== COPYING IMAGE FROM HARBOR TO ECR ====="
echo "Source image: ${HARBOR_IMAGE}"
echo "Target image: ${ECR_IMAGE}"

# Step 1: Login to Harbor
echo "Logging in to Harbor..."
echo "${HARBOR_PASSWORD}" | docker login "${HARBOR_REGISTRY}" -u "${HARBOR_USERNAME}" --password-stdin

# Step 2: Pull the image from Harbor
echo "Pulling image from Harbor..."
docker pull "${HARBOR_IMAGE}"

# Step 3: Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Step 4: Create ECR repository if it doesn't exist
echo "Creating ECR repository if it doesn't exist..."
aws ecr describe-repositories --repository-names "${ECR_REPO}" --region "${AWS_REGION}" || \
    aws ecr create-repository --repository-name "${ECR_REPO}" --region "${AWS_REGION}"

# Step 5: Tag the image for ECR
echo "Tagging image for ECR..."
docker tag "${HARBOR_IMAGE}" "${ECR_IMAGE}"

# Step 6: Push to ECR
echo "Pushing image to ECR..."
docker push "${ECR_IMAGE}"

echo "===== IMAGE SUCCESSFULLY COPIED TO ECR ====="
echo "ECR Image: ${ECR_IMAGE}"