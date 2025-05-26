# EMCP CI/CD Process

This document describes the CI/CD workflows and deployment processes for the EMCP project.

## Overview

The EMCP project uses GitHub Actions for automated deployment to AWS EKS with a multi-environment setup. The CI/CD pipeline supports both automatic deployments triggered by branch pushes and manual deployments via GitHub UI.

## Workflow Structure

### Main Orchestration Workflow

**File**: `.github/workflows/deploy-emcp.yml`

This is the primary workflow that orchestrates all service deployments. It contains the following jobs:

1. **set-environment** - Determines target environment based on branch or manual input
2. **check-changes** - Identifies which services need deployment based on file changes
3. **deploy-redis** - Deploys Redis cache service
4. **deploy-mongodb** - Deploys MongoDB database service  
5. **deploy-admin** - Deploys admin service
6. **deploy-backend** - Deploys backend API service
7. **deploy-frontend** - Deploys frontend web application
8. **deployment-summary** - Provides final deployment status report

### Trigger Mechanisms

#### Automatic Triggers (Push Events)
- **main branch** → Production environment (`emcp-prod`)
- **staging branch** → Staging environment (`emcp-staging`)
- **dev branch** → Development environment (`emcp-dev`)

#### Manual Triggers (workflow_dispatch)
- Environment selection: dev, staging, prod
- Service-specific deployment flags
- Special options like `check_redis_only`

### Change Detection Logic

The pipeline includes intelligent change detection that only deploys services when relevant files are modified:

**Monitored Paths**:
- `charts/{service}/templates/**`
- `charts/{service}/Chart.yaml`
- `charts/{service}/values.yaml`
- `charts/{service}/environments/*.yaml`
- `.github/workflows/**`

**Change Detection Rules**:
- For push events: Compares current commit with previous commit
- For manual dispatch: Uses input flags to determine deployments
- Only triggers deployment if specific service files are modified

## Custom GitHub Actions

### 1. Setup EKS Action
**Path**: `.github/actions/setup-eks/action.yml`

**Purpose**: Configures AWS credentials, kubectl, and Helm for EKS deployment

**Steps**:
1. Configure AWS credentials using `aws-actions/configure-aws-credentials@v2`
2. Update kubeconfig for EKS cluster connection
3. Install Helm v3.12.0
4. Create target namespace if it doesn't exist

### 2. Create ECR Credentials Action
**Path**: `.github/actions/create-ecr-credentials/action.yml`

**Purpose**: Creates Kubernetes secrets for ECR authentication

**Process**:
1. Retrieve ECR login token using AWS CLI
2. Create `docker-registry` secret in target namespace
3. Configure secret for ECR image pulling

### 3. Deploy Helm Chart Action
**Path**: `.github/actions/deploy-helm-chart/action.yml`

**Purpose**: Intelligent Helm deployment with skip logic

**Key Features**:
- **Smart Deployment Detection**: Checks if service already exists with correct image
- **Resource Type Handling**: Supports both StatefulSets and Deployments
- **Error Recovery**: Handles Helm timeout issues with actual pod status verification
- **Deployment Verification**: Post-deployment rollout status checking

**Deployment Logic Flow**:
1. Check if service already exists in namespace
2. Determine resource type (StatefulSet vs Deployment)
3. Verify current pod status and image version
4. Skip deployment if correct image is already running
5. Execute Helm upgrade/install if needed
6. Handle Helm timeouts gracefully
7. Verify final deployment status

## Service-Specific Workflows

### Individual Service Workflows
Each service has its own reusable workflow:

- `deploy-admin.yml` - Admin service deployment
- `deploy-backend.yml` - Backend API deployment  
- `deploy-frontend.yml` - Frontend application deployment
- `deploy-mongodb.yml` - MongoDB database deployment
- `deploy-redis.yml` - Redis cache deployment

### Common Workflow Pattern

Each service workflow follows this pattern:

1. **Environment Setup**
   - Checkout code
   - Setup EKS connection
   - Create ECR credentials

2. **Image Tag Resolution**
   - Map environment to image tag (dev/staging/prod)
   - Construct full ECR image path

3. **Configuration Setup**
   - Determine logging settings based on environment
   - Set environment-specific configurations

4. **Deployment Execution**
   - Use `deploy-helm-chart` action
   - Apply environment-specific values files
   - Set dynamic Helm values

5. **Status Reporting**
   - Report deployment status
   - Show pod details and service status

## Deployment Dependencies

Services are deployed in a specific order to respect dependencies: