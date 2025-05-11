#!/bin/bash
# 2-create-helm-structure.sh
# Script to create Helm chart directory structure

set -e
echo "Creating Helm chart directory structure..."

# Base directory for the repository
REPO_DIR="$(pwd)"
CHARTS_DIR="${REPO_DIR}/charts"
TEMP_DIR="${REPO_DIR}/temp"

# Services to extract based on observed pods
SERVICES=(
  "admin"
  "backend"
  "frontend"
  "keycloak"
  "mongodb"
  "redis"
  "emcp-prod-keycloak"
)

# Create charts directory
mkdir -p "${CHARTS_DIR}"

for SERVICE in "${SERVICES[@]}"; do
  # Normalize service name for chart
  CHART_NAME=$(echo $SERVICE | sed 's/-/_/g')
  
  echo "Creating chart structure for ${SERVICE}..."
  mkdir -p "${CHARTS_DIR}/${CHART_NAME}/templates"
  mkdir -p "${CHARTS_DIR}/${CHART_NAME}/environments"
  
  # Create base Chart.yaml
  cat > "${CHARTS_DIR}/${CHART_NAME}/Chart.yaml" << EOF
apiVersion: v2
name: ${CHART_NAME}
description: Helm chart for ${SERVICE} service
type: application
version: 0.1.0
appVersion: "1.0.0"
EOF

  # Create base values.yaml with common settings
  cat > "${CHARTS_DIR}/${CHART_NAME}/values.yaml" << EOF
# Default values for ${CHART_NAME}
# This is a YAML-formatted file.

replicaCount: 1

image:
  repository: harbor.enclaive.cloud/emcp/${SERVICE}
  tag: latest
  pullPolicy: IfNotPresent

imagePullSecrets:
  - name: harbor-creds

nameOverride: ""
fullnameOverride: ""

serviceAccount:
  create: true
  annotations: {}
  name: ""

podAnnotations: {}

podSecurityContext: {}

securityContext: {}

service:
  type: ClusterIP
  port: 80

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 256Mi

nodeSelector: {}

tolerations: []

affinity: {}

persistence:
  enabled: false
  storageClass: "longhorn"
  size: 5Gi

# Environment-specific configurations should be in environments/[env].yaml
EOF

  # Create environment-specific values
  for ENV in dev staging prod; do
    cat > "${CHARTS_DIR}/${CHART_NAME}/environments/${ENV}.yaml" << EOF
# Values specific to ${ENV} environment

replicaCount: $([ "$ENV" == "prod" ] && echo "2" || echo "1")

# Override service-specific configurations here
EOF
  done

  # Create _helpers.tpl for each chart
  cat > "${CHARTS_DIR}/${CHART_NAME}/templates/_helpers.tpl" << EOF
{{/*
Expand the name of the chart.
*/}}
{{- define "${CHART_NAME}.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "${CHART_NAME}.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- \$name := default .Chart.Name .Values.nameOverride }}
{{- if contains \$name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name \$name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "${CHART_NAME}.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "${CHART_NAME}.labels" -}}
helm.sh/chart: {{ include "${CHART_NAME}.chart" . }}
{{ include "${CHART_NAME}.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "${CHART_NAME}.selectorLabels" -}}
app.kubernetes.io/name: {{ include "${CHART_NAME}.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
EOF
done

echo "Helm chart structure created in ${CHARTS_DIR}/"
echo "Now you can run 3-process-resources.sh to process the extracted resources into Helm templates."