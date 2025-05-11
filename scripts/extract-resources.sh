#!/bin/bash
# 1-extract-resources.sh
# Script to extract Kubernetes resources from an existing cluster

set -e
echo "Starting resource extraction..."

# Base directory for the repository
REPO_DIR="$(pwd)"
NAMESPACE="emcp-prod"
TEMP_DIR="${REPO_DIR}/temp"

# Create temp directory
mkdir -p "${TEMP_DIR}"

# Extract various resource types from the namespace
extract_resources() {
  local resource_type=$1
  local output_dir=$2
  
  echo "Extracting ${resource_type}..."
  mkdir -p "${output_dir}/${resource_type}"
  
  kubectl get ${resource_type} -n ${NAMESPACE} -o name | while read resource; do
    name=$(echo $resource | cut -d/ -f2)
    kubectl get ${resource_type} ${name} -n ${NAMESPACE} -o yaml > "${output_dir}/${resource_type}/${name}.yaml"
    echo "Extracted ${resource_type}/${name}"
  done
}

# Extract main resources
extract_resources "deployment" "${TEMP_DIR}"
extract_resources "statefulset" "${TEMP_DIR}"
extract_resources "service" "${TEMP_DIR}"
extract_resources "configmap" "${TEMP_DIR}"
extract_resources "secret" "${TEMP_DIR}"
extract_resources "ingress" "${TEMP_DIR}"
extract_resources "pvc" "${TEMP_DIR}"
extract_resources "cronjob" "${TEMP_DIR}"

echo "Resource extraction completed. Files saved to ${TEMP_DIR}/"
echo "Now you can run 2-create-helm-structure.sh to create the Helm chart structure."