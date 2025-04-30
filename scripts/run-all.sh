#!/bin/bash
# run-all.sh
# Main script to run all extraction and processing steps

set -e
echo "Starting the Kubernetes to Helm migration process..."

# Check prerequisites
for cmd in kubectl yq; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: $cmd is not installed. Please install it before running this script."
    exit 1
  fi
done

# Check cluster connection
if ! kubectl get nodes &> /dev/null; then
  echo "Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
  exit 1
fi

# Create all required scripts
chmod +x extract-resources.sh
chmod +x create-helm-structure.sh
chmod +x process-resources.sh
chmod +x create-support-files.sh

# Run each script in sequence
echo "Step 1: Extracting resources from Kubernetes..."
./extract-resources.sh

echo "Step 2: Creating Helm chart structure..."
./create-helm-structure.sh

echo "Step 3: Processing resources into Helm templates..."
./process-resources.sh

echo "Step 4: Creating support files..."
./create-support-files.sh

echo "All steps completed successfully!"
echo ""
echo "Next steps:"
echo "1. Review the extracted Helm charts and adjust as needed"
echo "2. Run ./backup-namespace.sh to create a backup of your namespace with Velero"
echo "3. Use scripts/deploy.sh to deploy the charts to your target cluster"
echo "4. Push the repository to GitHub for CI/CD integration"