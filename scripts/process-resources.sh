#!/bin/bash
# 3-process-resources.sh
# Script to process the extracted resources and create Helm templates

set -e
echo "Processing extracted resources into Helm templates..."

# Base directory for the repository
REPO_DIR="$(pwd)"
NAMESPACE="emcp-prod"
CHARTS_DIR="${REPO_DIR}/charts"
TEMP_DIR="${REPO_DIR}/temp"

# Services to process
SERVICES=(
  "admin"
  "backend"
  "frontend"
  "keycloak"
  "mongodb"
  "redis"
  "emcp-prod-keycloak"
)

# Function to clean and templatize resource YAML
templatize_resource() {
  local file=$1
  local output_file=$2
  
  # Clean the YAML from cluster-specific data
  cat "${file}" | \
    yq eval 'del(.metadata.creationTimestamp)' - | \
    yq eval 'del(.metadata.resourceVersion)' - | \
    yq eval 'del(.metadata.uid)' - | \
    yq eval 'del(.metadata.selfLink)' - | \
    yq eval 'del(.metadata.generation)' - | \
    yq eval 'del(.status)' - | \
    yq eval 'del(.spec.template.spec.containers[].image)' - | \
    yq eval 'del(.spec.volumeClaimTemplates[].status)' - > "${output_file}"
  
  # Replace references to static values with Helm template variables
  # OS-aware sed for in-place editing
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS requires an extension argument for -i
    sed -i '' "s/namespace: ${NAMESPACE}/namespace: {{ .Release.Namespace }}/g" "${output_file}"
  else
    # Linux version
    sed -i "s/namespace: ${NAMESPACE}/namespace: {{ .Release.Namespace }}/g" "${output_file}"
  fi
}

# Process each extracted resource and place into appropriate Helm chart template directory
process_resources() {
  local resource_type=$1
  local chart_dir=$2
  local service=$3
  
  for file in "${TEMP_DIR}/${resource_type}"/*${service}*.yaml; do
    if [ -f "$file" ]; then
      # Get base filename
      filename=$(basename "$file")
      
      # Create templatized version
      templatize_resource "$file" "${chart_dir}/templates/${resource_type}-${filename}"
      
      echo "Processed ${resource_type}/${filename} into ${chart_dir}/templates/"
    fi
  done
}

# Match resources to their respective services and process them
for SERVICE in "${SERVICES[@]}"; do
  CHART_NAME=$(echo $SERVICE | sed 's/-/_/g')
  CHART_DIR="${CHARTS_DIR}/${CHART_NAME}"
  
  echo "Processing resources for ${SERVICE}..."
  
  # Process different resource types
  process_resources "deployment" "${CHART_DIR}" "${SERVICE}"
  process_resources "statefulset" "${CHART_DIR}" "${SERVICE}"
  process_resources "service" "${CHART_DIR}" "${SERVICE}"
  process_resources "configmap" "${CHART_DIR}" "${SERVICE}"
  process_resources "ingress" "${CHART_DIR}" "${SERVICE}"
  process_resources "pvc" "${CHART_DIR}" "${SERVICE}"
  process_resources "cronjob" "${CHART_DIR}" "${SERVICE}"
  
  # Secrets need special handling (we don't include actual secret values)
  for file in "${TEMP_DIR}/secret"/*${SERVICE}*.yaml; do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      
      # For secrets, we create a template but remove the data/stringData fields
      cat "${file}" | \
        yq eval 'del(.metadata.creationTimestamp)' - | \
        yq eval 'del(.metadata.resourceVersion)' - | \
        yq eval 'del(.metadata.uid)' - | \
        yq eval 'del(.metadata.selfLink)' - | \
        yq eval 'del(.metadata.generation)' - | \
        yq eval 'del(.status)' - | \
        yq eval 'del(.data)' - | \
        yq eval 'del(.stringData)' - > "${CHART_DIR}/templates/secret-${filename}"
      
      # Replace with a values reference
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/namespace: ${NAMESPACE}/namespace: {{ .Release.Namespace }}/g" "${CHART_DIR}/templates/secret-${filename}"
      else
        sed -i "s/namespace: ${NAMESPACE}/namespace: {{ .Release.Namespace }}/g" "${CHART_DIR}/templates/secret-${filename}"
      fi
      
      echo "Processed secret/${filename} into ${CHART_DIR}/templates/"
    fi
  done
  
  # Create a deployment if it doesn't exist (for services that use StatefulSets instead)
  if [ ! -f "${CHART_DIR}/templates/deployment-${SERVICE}.yaml" ] && [ ! -f "${CHART_DIR}/templates/statefulset-${SERVICE}.yaml" ]; then
    echo "Creating template for deployment-${SERVICE}.yaml..."
    
    # Basic deployment template
    cat > "${CHART_DIR}/templates/deployment-${SERVICE}.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "${CHART_NAME}.fullname" . }}
  labels:
    {{- include "${CHART_NAME}.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "${CHART_NAME}.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "${CHART_NAME}.selectorLabels" . | nindent 8 }}
      annotations:
        {{- toYaml .Values.podAnnotations | nindent 8 }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
EOF
  fi
done

echo "Resource processing completed. Helm templates created in chart directories."
echo "Now you can run 4-create-support-files.sh to create support scripts and files."