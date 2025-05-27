#!/bin/bash

# Kubernetes Secrets Backup Script
# Usage: ./backup-secrets.sh [namespace] [backup-directory]

set -e  # Exit on any error

# Default values
NAMESPACE="${1:-emcp-dev}"
BACKUP_DIR="${2:-${NAMESPACE}-secrets-backup-$(date +%Y%m%d-%H%M%S)}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    print_error "Namespace '$NAMESPACE' does not exist"
    exit 1
fi

# Check if there are any secrets to backup
SECRET_COUNT=$(kubectl get secrets -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
if [ "$SECRET_COUNT" -eq 0 ]; then
    print_warning "No secrets found in namespace '$NAMESPACE'"
    exit 0
fi

print_status "Starting backup of $SECRET_COUNT secrets from namespace: $NAMESPACE"
print_status "Backup directory: $BACKUP_DIR"

# Create backup directory
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

print_status "Created backup directory: $(pwd)"

# Step 1: Export all secrets to individual YAML files
print_status "Exporting individual secret files..."
mkdir -p individual-secrets

kubectl get secrets -n "$NAMESPACE" -o name | while IFS= read -r secret; do
    secret_name=$(echo "$secret" | cut -d'/' -f2)
    print_status "Backing up: $secret_name"
    kubectl get "$secret" -n "$NAMESPACE" -o yaml > "individual-secrets/${secret_name}.yaml"
done

# Step 2: Create combined backup files
print_status "Creating combined backup files..."

# All secrets in YAML format
kubectl get secrets -n "$NAMESPACE" -o yaml > all-secrets-backup.yaml
print_success "Created: all-secrets-backup.yaml"

# All secrets in JSON format
kubectl get secrets -n "$NAMESPACE" -o json > all-secrets-backup.json
print_success "Created: all-secrets-backup.json"

# Step 3: Create categorized backups
print_status "Creating categorized backups..."

# TLS secrets
if kubectl get secrets -n "$NAMESPACE" --field-selector type=kubernetes.io/tls --no-headers 2>/dev/null | grep -q .; then
    kubectl get secrets -n "$NAMESPACE" --field-selector type=kubernetes.io/tls -o yaml > tls-secrets-backup.yaml
    print_success "Created: tls-secrets-backup.yaml"
fi

# Helm release secrets
if kubectl get secrets -n "$NAMESPACE" -l owner=helm --no-headers 2>/dev/null | grep -q .; then
    kubectl get secrets -n "$NAMESPACE" -l owner=helm -o yaml > helm-secrets-backup.yaml
    print_success "Created: helm-secrets-backup.yaml"
fi

# Docker registry secrets
if kubectl get secrets -n "$NAMESPACE" --field-selector type=kubernetes.io/dockerconfigjson --no-headers 2>/dev/null | grep -q .; then
    kubectl get secrets -n "$NAMESPACE" --field-selector type=kubernetes.io/dockerconfigjson -o yaml > docker-secrets-backup.yaml
    print_success "Created: docker-secrets-backup.yaml"
fi

# Opaque secrets
if kubectl get secrets -n "$NAMESPACE" --field-selector type=Opaque --no-headers 2>/dev/null | grep -q .; then
    kubectl get secrets -n "$NAMESPACE" --field-selector type=Opaque -o yaml > opaque-secrets-backup.yaml
    print_success "Created: opaque-secrets-backup.yaml"
fi

# Step 4: Create summary and metadata
print_status "Creating backup metadata..."

# Secret summary
cat > secrets-summary.txt << EOF
Kubernetes Secrets Backup Summary
=================================
Namespace: $NAMESPACE
Backup Date: $(date)
Total Secrets: $SECRET_COUNT
Backup Directory: $(pwd)

Secret Details:
EOF

kubectl get secrets -n "$NAMESPACE" -o custom-columns=NAME:.metadata.name,TYPE:.type,DATA-KEYS:.data,AGE:.metadata.creationTimestamp --no-headers >> secrets-summary.txt

print_success "Created: secrets-summary.txt"

# Step 5: Create restore script
print_status "Creating restore script..."

cat > restore-secrets.sh << 'EOF'
#!/bin/bash

# Kubernetes Secrets Restore Script
# Usage: ./restore-secrets.sh [target-namespace]

set -e

ORIGINAL_NAMESPACE="NAMESPACE_PLACEHOLDER"
TARGET_NAMESPACE="${1:-$ORIGINAL_NAMESPACE}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

print_status "Restoring secrets to namespace: $TARGET_NAMESPACE"

# Create namespace if it doesn't exist
if ! kubectl get namespace "$TARGET_NAMESPACE" &> /dev/null; then
    print_status "Creating namespace: $TARGET_NAMESPACE"
    kubectl create namespace "$TARGET_NAMESPACE"
fi

# Check if backup file exists
if [ ! -f "all-secrets-backup.yaml" ]; then
    print_error "Backup file 'all-secrets-backup.yaml' not found"
    exit 1
fi

# Create a temporary file with the correct namespace
print_status "Preparing secrets for target namespace..."
sed "s/namespace: $ORIGINAL_NAMESPACE/namespace: $TARGET_NAMESPACE/g" all-secrets-backup.yaml > temp-restore.yaml

# Apply the secrets
print_status "Applying secrets..."
kubectl apply -f temp-restore.yaml

# Clean up
rm temp-restore.yaml

# Verify restoration
RESTORED_COUNT=$(kubectl get secrets -n "$TARGET_NAMESPACE" --no-headers | wc -l)
print_success "Successfully restored $RESTORED_COUNT secrets to namespace: $TARGET_NAMESPACE"

print_status "Restoration completed!"
EOF

# Replace placeholder in restore script
sed -i "s/NAMESPACE_PLACEHOLDER/$NAMESPACE/" restore-secrets.sh
chmod +x restore-secrets.sh

print_success "Created: restore-secrets.sh"

# Step 6: Create cleanup script
print_status "Creating cleanup script for original namespace..."

cat > cleanup-namespace.sh << EOF
#!/bin/bash

# Cleanup script for namespace: $NAMESPACE
# This script will delete all secrets and force-delete the namespace

set -e

NAMESPACE="$NAMESPACE"

echo "WARNING: This will delete all secrets in namespace '\$NAMESPACE' and force-delete the namespace!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "\$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Deleting all secrets in namespace: \$NAMESPACE"
kubectl delete secrets --all -n "\$NAMESPACE" --force --grace-period=0 || true

echo "Removing finalizers from remaining secrets..."
kubectl get secrets -n "\$NAMESPACE" -o name 2>/dev/null | xargs -I {} kubectl patch {} -p '{"metadata":{"finalizers":[]}}' --type=merge -n "\$NAMESPACE" || true

echo "Removing namespace finalizers..."
kubectl patch namespace "\$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge || true

echo "Verifying namespace deletion..."
if kubectl get namespace "\$NAMESPACE" &> /dev/null; then
    echo "ERROR: Namespace still exists. Manual intervention may be required."
else
    echo "SUCCESS: Namespace '\$NAMESPACE' has been deleted."
fi
EOF

chmod +x cleanup-namespace.sh
print_success "Created: cleanup-namespace.sh"

# Step 7: Create archive
print_status "Creating compressed archive..."
cd ..
ARCHIVE_NAME="${BACKUP_DIR}.tar.gz"
tar -czf "$ARCHIVE_NAME" "$BACKUP_DIR/"
print_success "Created archive: $ARCHIVE_NAME"

# Step 8: Final summary
cd "$BACKUP_DIR"
print_success "Backup completed successfully!"
echo
echo "==================================="
echo "BACKUP SUMMARY"
echo "==================================="
echo "Namespace: $NAMESPACE"
echo "Secrets backed up: $SECRET_COUNT"
echo "Backup location: $(pwd)"
echo "Archive: ../$ARCHIVE_NAME"
echo
echo "Files created:"
ls -la *.yaml *.json *.txt *.sh 2>/dev/null || true
echo
echo "Individual secrets: $(ls individual-secrets/ | wc -l) files"
echo
echo "Next steps:"
echo "1. Review the backup files"
echo "2. Run './cleanup-namespace.sh' to delete the original namespace"
echo "3. Use './restore-secrets.sh [namespace]' to restore secrets later"
echo "==================================="