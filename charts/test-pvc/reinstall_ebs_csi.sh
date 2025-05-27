#!/bin/bash

# EBS CSI Driver Installation - Let EKS choose the version
set -e

CLUSTER_NAME="emcp-eks-cluster"
AWS_REGION="eu-central-1"
AWS_ACCOUNT_ID="886093416603"



# Step 4: Create service account
echo -e "\n4. Creating service account..."
kubectl delete serviceaccount ebs-csi-controller-sa -n kube-system 2>/dev/null || true

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ebs-csi-controller-sa
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME
EOF

# Step 5: Install addon WITHOUT specifying version (EKS will choose default)
echo -e "\n5. Installing EBS CSI addon (EKS will choose the version)..."
aws eks create-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name aws-ebs-csi-driver \
    --service-account-role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$ROLE_NAME \
    --region $AWS_REGION \
    --resolve-conflicts OVERWRITE

echo "✅ EBS CSI addon installation initiated"

# Step 6: Wait for addon to be active
echo -e "\n6. Waiting for addon to be active..."
aws eks wait addon-active \
    --cluster-name $CLUSTER_NAME \
    --addon-name aws-ebs-csi-driver \
    --region $AWS_REGION

echo "✅ EBS CSI addon is active"

# Step 7: Check what version was installed
echo -e "\n7. Checking installed version..."
INSTALLED_VERSION=$(aws eks describe-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name aws-ebs-csi-driver \
    --region $AWS_REGION \
    --query 'addon.addonVersion' \
    --output text)

echo "EKS chose version: $INSTALLED_VERSION"

# Step 8: Verify installation
echo -e "\n8. Verifying installation..."
kubectl get pods -n kube-system -l app=ebs-csi-controller
kubectl get pods -n kube-system -l app=ebs-csi-node
kubectl get csidriver ebs.csi.aws.com

# Step 9: Create storage class
echo -e "\n9. Creating storage class..."

# Remove default from old gp3
kubectl annotate storageclass gp3 storageclass.kubernetes.io/is-default-class- 2>/dev/null || true

# Create GP3 storage class (default)
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  fsType: ext4
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
reclaimPolicy: Delete
EOF

echo "✅ Storage class created"

# Step 10: Test with PVC
echo -e "\n10. Testing with a PVC..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-ebs-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
EOF

echo "Waiting for PVC to bind..."
sleep 30

PVC_STATUS=$(kubectl get pvc test-ebs-pvc -n default -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
echo "Test PVC status: $PVC_STATUS"

if [ "$PVC_STATUS" = "Bound" ]; then
    echo "✅ EBS CSI driver is working!"
    kubectl delete pvc test-ebs-pvc -n default
else
    echo "❌ PVC not bound, checking details..."
    kubectl describe pvc test-ebs-pvc -n default
fi

# Step 11: Final status
echo -e "\n=== FINAL STATUS ==="
aws eks describe-addon \
    --cluster-name $CLUSTER_NAME \
    --addon-name aws-ebs-csi-driver \
    --region $AWS_REGION \
    --query 'addon.{Status:status,Version:addonVersion,Health:health}'

echo -e "\nStorage classes:"
kubectl get storageclass

echo -e "\nCSI nodes:"
kubectl get csinodes

# Cleanup
rm -f trust-policy.json

echo -e "\n✅ Installation complete!"
echo "Version chosen by EKS: $INSTALLED_VERSION"
echo -e "\nNow clean up VHSM and redeploy:"
echo "kubectl delete pvc data-vhsm-0 data-vhsm-1 data-vhsm-2 -n emcp-dev --force"
echo "kubectl delete statefulset vhsm -n emcp-dev"