#!/bin/bash
# MongoDB deployment pre-validation script
# Run this before deploying MongoDB to validate configuration

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "\n${GREEN}========== MongoDB Deployment Validation Script ==========${NC}\n"

# Variables - modify as needed
CHART_PATH="./charts/mongo"
NAMESPACE="emcp-dev"  # Default namespace, can be overridden with -n flag
VALUES_FILE=""

# Process command line arguments
while getopts ":n:f:" opt; do
  case ${opt} in
    n )
      NAMESPACE=$OPTARG
      ;;
    f )
      VALUES_FILE="--values $OPTARG"
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid Option: -$OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done

echo -e "${GREEN}Validating MongoDB Helm Chart in namespace: ${YELLOW}$NAMESPACE${NC}"
if [ ! -z "$VALUES_FILE" ]; then
  echo -e "${GREEN}Using values file: ${YELLOW}$VALUES_FILE${NC}"
fi

# Check 1: Validate chart syntax
echo -e "\n${GREEN}1. Validating Helm chart syntax...${NC}"
helm lint $CHART_PATH $VALUES_FILE || {
  echo -e "${RED}❌ Helm chart has syntax errors.${NC}"
  exit 1
}
echo -e "${GREEN}✅ Helm chart syntax is valid.${NC}"

# Check 2: Validate template rendering
echo -e "\n${GREEN}2. Validating template rendering...${NC}"
helm template mongodb $CHART_PATH $VALUES_FILE --namespace $NAMESPACE > /tmp/mongodb-rendered.yaml || {
  echo -e "${RED}❌ Failed to render Helm templates.${NC}"
  exit 1
}
echo -e "${GREEN}✅ Templates render successfully.${NC}"

# Check 3: Check for StatefulSet in rendered output
echo -e "\n${GREEN}3. Checking for MongoDB StatefulSet...${NC}"
if grep -q "kind: StatefulSet" /tmp/mongodb-rendered.yaml && grep -q "name: mongodb" /tmp/mongodb-rendered.yaml; then
  echo -e "${GREEN}✅ MongoDB StatefulSet definition found.${NC}"
else
  echo -e "${RED}❌ MongoDB StatefulSet definition not found in rendered templates.${NC}"
  exit 1
fi

# Check 4: Check for volume claim templates
echo -e "\n${GREEN}4. Checking for volume claim templates...${NC}"
if grep -q "volumeClaimTemplates:" /tmp/mongodb-rendered.yaml; then
  echo -e "${GREEN}✅ Volume claim templates found.${NC}"
else
  echo -e "${RED}❌ Volume claim templates not found in StatefulSet.${NC}"
  exit 1
fi

# Check 5: Check for secrets
echo -e "\n${GREEN}5. Checking for MongoDB credentials secret...${NC}"
if grep -q "kind: Secret" /tmp/mongodb-rendered.yaml && grep -q "name: mongodb-credentials" /tmp/mongodb-rendered.yaml; then
  echo -e "${GREEN}✅ MongoDB credentials secret found.${NC}"
else
  echo -e "${RED}❌ MongoDB credentials secret not found in rendered templates.${NC}"
  exit 1
fi

# Check 6: Check for backup PVC if backups are enabled
echo -e "\n${GREEN}6. Checking for backup PVC...${NC}"
if grep -q "name: mongodb-backup-pvc" /tmp/mongodb-rendered.yaml; then
  echo -e "${GREEN}✅ Backup PVC found.${NC}"
else
  echo -e "${YELLOW}⚠️ Backup PVC not found. Make sure backups are properly configured.${NC}"
fi

# Check 7: Check security settings
echo -e "\n${GREEN}7. Checking security settings...${NC}"
if grep -q "valueFrom:" /tmp/mongodb-rendered.yaml && grep -q "secretKeyRef:" /tmp/mongodb-rendered.yaml; then
  echo -e "${GREEN}✅ Secrets references found in pod specs.${NC}"
else
  echo -e "${RED}❌ Pod specs don't use secretKeyRef for sensitive data.${NC}"
  exit 1
fi

# Check 8: Check for resource requests and limits
echo -e "\n${GREEN}8. Checking resource allocation...${NC}"
if grep -q "resources:" /tmp/mongodb-rendered.yaml; then
  echo -e "${GREEN}✅ Resource allocation found.${NC}"
else
  echo -e "${YELLOW}⚠️ No resource limits/requests found. Consider adding them.${NC}"
fi

# Check 9: Dry-run server-side validation
echo -e "\n${GREEN}9. Running server-side validation...${NC}"
kubectl create --dry-run=server -f /tmp/mongodb-rendered.yaml > /dev/null || {
  echo -e "${RED}❌ Server-side validation failed. Resources may not be valid for your cluster.${NC}"
  exit 1
}
echo -e "${GREEN}✅ Server-side validation passed.${NC}"

echo -e "\n${GREEN}All validation checks passed! MongoDB deployment is ready.${NC}"
echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "1. Deploy MongoDB: ${GREEN}helm upgrade --install mongodb $CHART_PATH $VALUES_FILE --namespace $NAMESPACE${NC}"
echo -e "2. Verify pods: ${GREEN}kubectl get pods -n $NAMESPACE -l app=mongodb${NC}"
echo -e "3. Check PVCs: ${GREEN}kubectl get pvc -n $NAMESPACE -l app=mongodb${NC}"

exit 0