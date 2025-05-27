#!/bin/bash

# Configuration
SOURCE_CONTEXT="ucak"
DEST_CONTEXT="arn:aws:eks:eu-central-1:886093416603:cluster/emcp-eks-cluster"
SOURCE_NAMESPACE="emcp-deve"
DEST_NAMESPACE="emcp-deve"

# Script banner
echo "========================================================"
echo "Kubernetes Secret Migration Script"
echo "Source: $SOURCE_CONTEXT (namespace: $SOURCE_NAMESPACE)"
echo "Destination: $DEST_CONTEXT (namespace: $DEST_NAMESPACE)"
echo "========================================================"

# Check if source context exists
if ! kubectl config get-contexts $SOURCE_CONTEXT -o name &>/dev/null; then
  echo "Error: Source context '$SOURCE_CONTEXT' not found"
  exit 1
fi

# Check if destination context exists
if ! kubectl config get-contexts $DEST_CONTEXT -o name &>/dev/null; then
  echo "Error: Destination context '$DEST_CONTEXT' not found"
  exit 1
fi

# Check if source namespace exists
if ! kubectl --context=$SOURCE_CONTEXT get namespace $SOURCE_NAMESPACE &>/dev/null; then
  echo "Error: Source namespace '$SOURCE_NAMESPACE' not found in context '$SOURCE_CONTEXT'"
  exit 1
fi

# Create destination namespace if it doesn't exist
if ! kubectl --context=$DEST_CONTEXT get namespace $DEST_NAMESPACE &>/dev/null; then
  echo "Creating namespace '$DEST_NAMESPACE' in destination cluster..."
  kubectl --context=$DEST_CONTEXT create namespace $DEST_NAMESPACE
fi

# Count total secrets for progress tracking
TOTAL_SECRETS=$(kubectl --context=$SOURCE_CONTEXT -n $SOURCE_NAMESPACE get secrets --no-headers | wc -l)
COUNTER=0
COPIED=0
SKIPPED=0

echo "Found $TOTAL_SECRETS secrets in source namespace"
echo "Starting migration..."

# Create temp directory for secret files
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Get all secrets from source namespace
kubectl --context=$SOURCE_CONTEXT -n $SOURCE_NAMESPACE get secrets -o name | while read SECRET_PATH; do
  # Extract secret name from path (remove prefix "secret/")
  SECRET_NAME=${SECRET_PATH#secret/}
  COUNTER=$((COUNTER+1))
  
  # Get secret type
  SECRET_TYPE=$(kubectl --context=$SOURCE_CONTEXT -n $SOURCE_NAMESPACE get secret $SECRET_NAME -o jsonpath='{.type}')
  
  # Skip Kubernetes service account tokens and default tokens
  if [[ "$SECRET_TYPE" == "kubernetes.io/service-account-token" || "$SECRET_NAME" == "default-token-"* ]]; then
    echo "[$COUNTER/$TOTAL_SECRETS] Skipping service account token: $SECRET_NAME"
    SKIPPED=$((SKIPPED+1))
    continue
  fi
  
  echo "[$COUNTER/$TOTAL_SECRETS] Copying secret: $SECRET_NAME (Type: $SECRET_TYPE)"
  
  # Export secret to YAML file, removing specific metadata
  SECRET_FILE="$TEMP_DIR/$SECRET_NAME.yaml"
  kubectl --context=$SOURCE_CONTEXT -n $SOURCE_NAMESPACE get secret $SECRET_NAME -o yaml | \
    sed '/resourceVersion:/d; /uid:/d; /creationTimestamp:/d; /selfLink:/d; /managedFields:/d; /ownerReferences:/d; /generation:/d' > $SECRET_FILE
  
  # Check if export was successful
  if [ ! -s "$SECRET_FILE" ]; then
    echo "  Error: Failed to export secret $SECRET_NAME"
    continue
  fi
  
  # Apply to destination cluster
  if kubectl --context=$DEST_CONTEXT -n $DEST_NAMESPACE apply -f $SECRET_FILE; then
    echo "  Success: Secret applied to destination cluster"
    COPIED=$((COPIED+1))
  else
    echo "  Error: Failed to apply secret to destination cluster"
  fi
done

# Cleanup
echo "Cleaning up temporary files..."
rm -rf $TEMP_DIR

# Summary
echo "========================================================"
echo "Migration Summary:"
echo "  Total secrets found: $TOTAL_SECRETS"
echo "  Successfully copied: $COPIED"
echo "  Skipped (system tokens): $SKIPPED"
echo "  Failed: $((TOTAL_SECRETS - COPIED - SKIPPED))"
echo "========================================================"

if [ $COPIED -eq 0 ]; then
  echo "No secrets were copied. Please check for errors above."
  exit 1
else
  echo "Secret migration completed!"
fi