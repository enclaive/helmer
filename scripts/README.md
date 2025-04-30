# Helmer - Helm Charts for emcp Services

This repository contains Helm charts for deploying emcp services to Kubernetes.

## Repository Structure

```
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
```

## Getting Started

### Prerequisites

- Kubernetes cluster
- Helm 3
- kubectl
- Access to Harbor container registry

### Deploying Charts

1. Clone this repository
2. Update the environment-specific values in `charts/<service>/environments/<env>.yaml`
3. Run the deployment script:

```bash
export HARBOR_USERNAME=your-username
export HARBOR_PASSWORD=your-password
./scripts/deploy.sh <namespace> <environment>
```

For example:

```bash
./scripts/deploy.sh emcp-dev dev
```

### Updating Image Tags

To update the image tag for a service:

```bash
./scripts/update-image.sh <service> <tag> <environment>
```

For example:

```bash
./scripts/update-image.sh backend main-abc123 prod
```

## Backup and Restore

This repository includes a script to create a backup of the entire namespace using Velero:

```bash
./backup-namespace.sh
```

To restore from a backup:

```bash
velero restore create --from-backup <backup-name> --namespace-mappings emcp-prod:new-namespace
```

## CI/CD

The repository includes GitHub Actions workflows for:

1. Detecting changes to specific Helm charts
2. Deploying charts to Kubernetes

Configure the following secrets in your GitHub repository:

- `KUBECONFIG`: Base64-encoded kubeconfig file
- `HARBOR_USERNAME`: Harbor registry username
- `HARBOR_PASSWORD`: Harbor registry password
