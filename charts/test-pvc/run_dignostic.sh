#!/bin/bash

echo "=== Proper Storage Diagnosis for EKS ==="

# Your storage classes are actually fine:
# - gp3: Legacy AWS EBS provisioner (works but deprecated)
# - gp3: Modern EBS CSI with WaitForFirstConsumer (CORRECT)
# - gp3-immediate: EBS CSI with Immediate binding (can cause issues)

echo "1. Let's check the REAL issue - CSI Node topology labels..."
kubectl describe csinodes

echo -e "\n2. Check if nodes have proper topology labels..."
kubectl get nodes -o custom-columns="NAME:.metadata.name,ZONE:.metadata.labels.topology\.ebs\.csi\.aws\.com/zone"

echo -e "\n3. Check EBS CSI controller logs for the real error..."
kubectl logs -n kube-system -l app=ebs-csi-controller --tail=50

echo -e "\n=== THE REAL ISSUE ANALYSIS ==="
echo "From your PVC error: 'no topology key found on CSINode i-0411a763f9cdfe080'"
echo "This means the node is missing the topology.ebs.csi.aws.com/zone label"

echo -e "\n4. Let's check what's wrong with that specific node..."
kubectl describe csinode i-0411a763f9cdfe080

echo -e "\n=== FIXING THE TOPOLOGY ISSUE ==="

echo "5. The issue is likely that your nodes don't have proper topology labels."
echo "Let's fix this by adding the missing labels to nodes..."

# Get all nodes and their AZ from AWS metadata
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    echo "Checking node: $node"
    
    # Get the node's availability zone from AWS
    instance_id=$(kubectl get node $node -o jsonpath='{.spec.providerID}' | cut -d'/' -f5)
    if [ -n "$instance_id" ]; then
        az=$(aws ec2 describe-instances --instance-ids $instance_id --region eu-central-1 --query 'Reservations[0].Instances[0].Placement.AvailabilityZone' --output text 2>/dev/null)
        
        if [ -n "$az" ] && [ "$az" != "None" ]; then
            echo "  Instance: $instance_id, AZ: $az"
            
            # Add the topology label if missing
            kubectl label node $node topology.ebs.csi.aws.com/zone=$az --overwrite
            echo "  ✅ Added topology label: topology.ebs.csi.aws.com/zone=$az"
        else
            echo "  ❌ Could not determine AZ for $instance_id"
        fi
    else
        echo "  ❌ Could not get instance ID for node $node"
    fi
done

echo -e "\n6. Restart EBS CSI controller to pick up the changes..."
kubectl rollout restart daemonset ebs-csi-node -n kube-system
kubectl rollout restart deployment ebs-csi-controller -n kube-system

echo -e "\n7. Wait for EBS CSI pods to be ready..."
kubectl wait --for=condition=ready pod -l app=ebs-csi-controller -n kube-system --timeout=60s
kubectl wait --for=condition=ready pod -l app=ebs-csi-node -n kube-system --timeout=60s

echo -e "\n8. Clean up the stuck VHSM resources..."
NAMESPACE="emcp-deve"

# Force delete stuck resources
kubectl delete pod vhsm-0 vhsm-1 vhsm-2 -n $NAMESPACE --force --grace-period=0 2>/dev/null || true
kubectl delete statefulset vhsm -n $NAMESPACE 2>/dev/null || true
kubectl delete pvc data-vhsm-0 data-vhsm-1 data-vhsm-2 -n $NAMESPACE 2>/dev/null || true

echo -e "\n9. Test storage with a simple PVC using your existing gp3..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-storage
  namespace: $NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
EOF

echo -e "\n10. Checking if the test PVC binds..."
sleep 10
kubectl get pvc test-storage -n $NAMESPACE
kubectl describe pvc test-storage -n $NAMESPACE

echo -e "\n=== VERIFICATION ==="
echo "Check if nodes now have proper topology labels:"
kubectl get nodes -o custom-columns="NAME:.metadata.name,ZONE:.metadata.labels.topology\.ebs\.csi\.aws\.com/zone"

echo -e "\nCheck CSI nodes:"
kubectl get csinodes

echo -e "\nIf test PVC is now 'Bound', the issue is fixed!"
echo "You can then redeploy VHSM using storageClassName: gp3"

echo -e "\nClean up test PVC when done:"
echo "kubectl delete pvc test-storage -n $NAMESPACE"