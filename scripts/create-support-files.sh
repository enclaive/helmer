#!/bin/bash
# 4-create-support-files.sh
# Script to create supporting files like deployment scripts, backup scripts, etc.

set -e
echo "Creating support files..."

# Base directory for the repository
REPO_DIR="$(pwd)"
NAMESPACE="emcp-prod"

# Create scripts directory
mkdir -p "${REPO_DIR}/scripts"
mkdir -p "${REPO_DIR}/.github/workflows"

# Create a Velero backup script
echo "Creating Velero backup script..."
cat > "${REPO_DIR}/backup-namespace.sh" << EOF
#!/bin/bash
# Script to backup the ${NAMESPACE} namespace using Velero

# Check if Velero CLI is installed
if ! command -v velero &> /dev/null; then
  echo "Velero CLI is not installed. Please install it first."
  exit 1
fi

# Create the backup
BACKUP_NAME="${NAMESPACE}-\$(date +%Y%m%d-%H%M%S)"
echo "Creating backup \${BACKUP_NAME}..."

velero backup create \${BACKUP_NAME} \\
  --include-namespaces ${NAMESPACE} \\
  --default-volumes-to-fs-backup \\
  --wait

echo "Backup \${BACKUP_NAME} completed."
echo "To restore this backup to another cluster, run:"
echo "velero restore create --from-backup \${BACKUP_NAME} --namespace-mappings ${NAMESPACE}:new-namespace"
EOF

# Make the backup script executable
chmod +x "${REPO_DIR}/backup-namespace.sh"

# Create a deployment script
echo "Creating deployment script..."
cat > "${REPO_DIR}/scripts/deploy.sh" << EOF
#!/bin/bash
# Script to deploy Helm charts to a Kubernetes cluster

set -e

NAMESPACE=\$1
ENVIRONMENT=\$2

if [ -z "\$NAMESPACE" ] || [ -z "\$ENVIRONMENT" ]; then
  echo "Usage: \$0 <namespace> <environment>"
  echo "Example: \$0 emcp-prod prod"
  exit 1
fi

# Create namespace if it doesn't exist
kubectl get namespace \$NAMESPACE > /dev/null 2>&1 || kubectl create namespace \$NAMESPACE

# Create harbor-creds secret if needed
kubectl get secret harbor-creds -n \$NAMESPACE > /dev/null 2>&1 || \\
kubectl create secret docker-registry harbor-creds \\
  --docker-server=harbor.enclaive.cloud \\
  --docker-username=\$HARBOR_USERNAME \\
  --docker-password=\$HARBOR_PASSWORD \\
  --namespace=\$NAMESPACE

# Deploy each chart
for CHART_DIR in ./charts/*; do
  CHART_NAME=\$(basename \$CHART_DIR)
  
  echo "Deploying \$CHART_NAME to \$NAMESPACE (\$ENVIRONMENT environment)..."
  
  helm upgrade --install \\
    --namespace \$NAMESPACE \\
    --values \$CHART_DIR/environments/\$ENVIRONMENT.yaml \\
    \$CHART_NAME-\$ENVIRONMENT \\
    \$CHART_DIR
done

echo "Deployment completed successfully."
EOF

# Create image update script
echo "Creating image update script..."
cat > "${REPO_DIR}/scripts/update-image.sh" << EOF
#!/bin/bash
# Script to update image tags in Helm values

set -e

SERVICE=\$1
TAG=\$2
ENVIRONMENT=\$3

if [ -z "\$SERVICE" ] || [ -z "\$TAG" ] || [ -z "\$ENVIRONMENT" ]; then
  echo "Usage: \$0 <service> <tag> <environment>"
  echo "Example: \$0 backend main-abc123 prod"
  exit 1
fi

# Convert service name to chart name (replace hyphens with underscores)
CHART_NAME=\$(echo \$SERVICE | sed 's/-/_/g')
VALUES_FILE="./charts/\$CHART_NAME/environments/\$ENVIRONMENT.yaml"

if [ ! -f "\$VALUES_FILE" ]; then
  echo "Values file not found: \$VALUES_FILE"
  exit 1
fi

# Add or update image tag in values file
if grep -q "^image:" "\$VALUES_FILE"; then
  # Check if tag is already defined
  if grep -q "^  tag:" "\$VALUES_FILE"; then
    # Update existing tag - use OS-aware sed
    if [[ "\$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/^  tag:.*\$/  tag: \$TAG/" "\$VALUES_FILE"
    else
      sed -i "s/^  tag:.*\$/  tag: \$TAG/" "\$VALUES_FILE"
    fi
  else
    # Add tag under existing image section
    if [[ "\$OSTYPE" == "darwin"* ]]; then
      sed -i '' "/^image:/a\\
  tag: \$TAG" "\$VALUES_FILE"
    else
      sed -i "/^image:/a\\  tag: \$TAG" "\$VALUES_FILE"
    fi
  fi
else
  # Add new image section with tag
  cat >> "\$VALUES_FILE" << EEOF
image:
  tag: \$TAG
EEOF
fi

echo "Updated image tag for \$SERVICE to \$TAG in \$ENVIRONMENT environment."
EOF

# Make scripts executable
chmod +x "${REPO_DIR}/scripts/deploy.sh"
chmod +x "${REPO_DIR}/scripts/update-image.sh"

# Create GitHub workflow for detecting changes
echo "Creating GitHub Actions workflows..."
cat > "${REPO_DIR}/.github/workflows/detect-changes.yaml" << EOF
name: Detect Chart Changes

on:
  push:
    branches:
      - main
    paths:
      - 'charts/**'
  pull_request:
    branches:
      - main
    paths:
      - 'charts/**'

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed_charts: \${{ steps.filter.outputs.changes }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
          
      - name: Detect changed charts
        id: filter
        uses: dorny/paths-filter@v2
        with:
          list-files: json
          filters: |
            admin:
              - 'charts/admin/**'
            backend:
              - 'charts/backend/**'
            frontend:
              - 'charts/frontend/**'
            keycloak:
              - 'charts/keycloak/**'
            mongodb:
              - 'charts/mongodb/**'
            redis:
              - 'charts/redis/**'
            emcp_prod_keycloak:
              - 'charts/emcp_prod_keycloak/**'
EOF

# Create GitHub workflow for deployment
cat > "${REPO_DIR}/.github/workflows/deploy.yaml" << EOF
name: Deploy Charts

on:
  workflow_run:
    workflows: ["Detect Chart Changes"]
    types:
      - completed
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'emcp-dev'
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: \${{ github.event.workflow_run.conclusion == 'success' || github.event_name == 'workflow_dispatch' }}
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
        
      - name: Set up Helm
        uses: azure/setup-helm@v3
        with:
          version: 'v3.10.0'
          
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
        
      - name: Configure Kubernetes
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: \${{ secrets.KUBECONFIG }}
          
      - name: Set environment variables
        run: |
          if [ "\${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "ENVIRONMENT=\${{ github.event.inputs.environment }}" >> \$GITHUB_ENV
            echo "NAMESPACE=\${{ github.event.inputs.namespace }}" >> \$GITHUB_ENV
          else
            echo "ENVIRONMENT=dev" >> \$GITHUB_ENV
            echo "NAMESPACE=emcp-dev" >> \$GITHUB_ENV
          fi
          
      - name: Deploy Helm charts
        env:
          HARBOR_USERNAME: \${{ secrets.HARBOR_USERNAME }}
          HARBOR_PASSWORD: \${{ secrets.HARBOR_PASSWORD }}
        run: |
          chmod +x ./scripts/deploy.sh
          ./scripts/deploy.sh \$NAMESPACE \$ENVIRONMENT
EOF

# Create README.md
echo "Creating README.md..."
cat > "${REPO_DIR}/README.md" << EOF
# Helmer - Helm Charts for emcp Services

This repository contains Helm charts for deploying emcp services to Kubernetes.

## Repository Structure

\`\`\`
helmer/
├── charts/                # Contains all service Helm charts
│   ├── admin/             # Helm chart for admin service
│   ├── backend/           # Helm chart for backend service
│   ├── frontend/          # Helm chart for frontend service
│   ├── keycloak/          # Helm chart for keycloak service
│   ├── mongodb/           # Helm chart for mongodb service
│   ├── redis/             # Helm chart for redis service
│   └── emcp_prod_keycloak/# Helm chart for emcp-prod-keycloak service
├── .github/               # CI/CD configuration
│   └── workflows/
│       ├── detect-changes.yaml  # Workflow to detect which charts changed
│       └── deploy.yaml          # Deployment workflow
├── scripts/               # Utility scripts
│   ├── update-image.sh    # Script to update image tags
│   └── deploy.sh          # Deployment script
└── README.md              # Documentation
\`\`\`

## Getting Started

### Prerequisites

- Kubernetes cluster
- Helm 3
- kubectl
- Access to Harbor container registry

### Deploying Charts

1. Clone this repository
2. Update the environment-specific values in \`charts/<service>/environments/<env>.yaml\`
3. Run the deployment script:

\`\`\`bash
export HARBOR_USERNAME=your-username
export HARBOR_PASSWORD=your-password
./scripts/deploy.sh <namespace> <environment>
\`\`\`

For example:

\`\`\`bash
./scripts/deploy.sh emcp-dev dev
\`\`\`

### Updating Image Tags

To update the image tag for a service:

\`\`\`bash
./scripts/update-image.sh <service> <tag> <environment>
\`\`\`

For example:

\`\`\`bash
./scripts/update-image.sh backend main-abc123 prod
\`\`\`

## Backup and Restore

This repository includes a script to create a backup of the entire namespace using Velero:

\`\`\`bash
./backup-namespace.sh
\`\`\`

To restore from a backup:

\`\`\`bash
velero restore create --from-backup <backup-name> --namespace-mappings emcp-prod:new-namespace
\`\`\`

## CI/CD

The repository includes GitHub Actions workflows for:

1. Detecting changes to specific Helm charts
2. Deploying charts to Kubernetes

Configure the following secrets in your GitHub repository:

- \`KUBECONFIG\`: Base64-encoded kubeconfig file
- \`HARBOR_USERNAME\`: Harbor registry username
- \`HARBOR_PASSWORD\`: Harbor registry password
EOF

echo "Support files created successfully."
echo "All scripts have been created in the repository."
echo ""
echo "To run the full extraction process:"
echo "1. Run ./1-extract-resources.sh to extract resources from Kubernetes"
echo "2. Run ./2-create-helm-structure.sh to create the Helm chart directory structure"
echo "3. Run ./3-process-resources.sh to process resources into Helm templates"
echo "4. Run ./4-create-support-files.sh to create support scripts and files"
echo ""
echo "After that, you can use ./backup-namespace.sh to create a Velero backup of your namespace."