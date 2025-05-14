#!/bin/bash

# common.sh - Shared functions and variables for deployment scripts

# Function to check if a deployment is ready
check_status() {
  local resource_type=$1
  local resource_name=$2
  local namespace=$3
  local max_attempts=30
  local wait_time=10
  local attempt=0

  echo "Checking status of $resource_type/$resource_name in namespace $namespace..."
  
  while [ $attempt -lt $max_attempts ]; do
    attempt=$((attempt + 1))
    
    if [ "$resource_type" == "statefulset" ]; then
      READY=$(kubectl get statefulset "$resource_name" -n "$namespace" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
      DESIRED=$(kubectl get statefulset "$resource_name" -n "$namespace" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    elif [ "$resource_type" == "deployment" ]; then
      READY=$(kubectl get deployment "$resource_name" -n "$namespace" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
      DESIRED=$(kubectl get deployment "$resource_name" -n "$namespace" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    else
      echo "Unsupported resource type: $resource_type"
      return 1
    fi
    
    echo "Status: $READY/$DESIRED replicas ready (attempt $attempt/$max_attempts)"
    
    if [ "$READY" == "$DESIRED" ] && [ "$DESIRED" != "0" ]; then
      echo "✅ $resource_type/$resource_name is ready!"
      return 0
    fi
    
    echo "Waiting for $resource_name to be ready... (sleeping $wait_time seconds)"
    sleep $wait_time
  done
  
  echo "❌ Timed out waiting for $resource_type/$resource_name to be ready."
  kubectl describe $resource_type/$resource_name -n $namespace
  kubectl get pods -n $namespace -l app=$resource_name
  return 1
}

# Function to ensure a namespace exists and is initialized properly
ensure_namespace() {
  local namespace=$1
  
  echo "Ensuring namespace $namespace exists..."
  kubectl create namespace "$namespace" --dry-run=client -o yaml | kubectl apply -f -
  
  # Add any namespace-specific initialization here if needed
}

# Function to check if Harbor credentials exist
ensure_harbor_creds() {
  local namespace=$1
  
  echo "Ensuring harbor-creds secret exists in namespace $namespace..."
  if kubectl get secret harbor-creds -n "$namespace" &>/dev/null; then
    echo "Harbor credentials already exist in namespace $namespace."
  else
    echo "Creating harbor-creds secret in namespace $namespace..."
    # This should be created by the GitHub Actions workflow before this script runs
    echo "WARNING: harbor-creds secret doesn't exist. Make sure it's created before deploying."
  fi
}

# Function to print environment information
print_env_info() {
  echo "=== Environment Information ==="
  echo "Namespace: ${NAMESPACE}"
  echo "MongoDB Image Tag: ${MONGODB_TAG:-5.0.2}"
  echo "Redis Image Tag: ${REDIS_TAG:-6.2-alpine}"
  echo "Admin Image Tag: ${ADMIN_TAG:-latest}"
  echo "==============================="
}

# Default timeouts
MONGODB_TIMEOUT="15m"
REDIS_TIMEOUT="10m"
ADMIN_TIMEOUT="10m"

# Print header
echo "======================================"
echo "Enclaive Deployment Script"
echo "======================================"

# Initialize
print_env_info