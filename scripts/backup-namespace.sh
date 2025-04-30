#!/bin/bash
# Script to backup the emcp-prod namespace using Velero

# Check if Velero CLI is installed
if ! command -v velero &> /dev/null; then
  echo "Velero CLI is not installed. Please install it first."
  exit 1
fi

# Create the backup
BACKUP_NAME="emcp-prod-$(date +%Y%m%d-%H%M%S)"
echo "Creating backup ${BACKUP_NAME}..."

velero backup create ${BACKUP_NAME} \
  --include-namespaces emcp-prod \
  --default-volumes-to-fs-backup \
  --wait

echo "Backup ${BACKUP_NAME} completed."
echo "To restore this backup to another cluster, run:"
echo "velero restore create --from-backup ${BACKUP_NAME} --namespace-mappings emcp-prod:new-namespace"
