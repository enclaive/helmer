#!/bin/bash

echo "=== FIXING ALL NODE TOPOLOGY LABELS ==="

echo "1. Current nodes and their topology labels:"
kubectl get nodes -o custom-columns="NAME:.metadata.name,ZONE:.metadata.labels.topology\.ebs\.csi\.aws\.com/zone,INSTANCE:.spec.providerID"

echo -e "\n2. Checking CSINodes:"
kubectl get csinodes

echo -e "\n3. Adding missing topology labels to ALL nodes..."

# Fix ALL nodes, not just some
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    echo "Processing node: $node"
    
    # Get instance ID from providerID
    instance_id=$(kubectl get node $node -o jsonpath='{.spec.providerID}' | cut -d'/' -f5)
    
    if [ -n "$instance_id" ]; then
        echo "  Instance ID: $instance_id"
        
        # Get AZ from AWS
        az=$(aws ec2 describe-instances \
            --instance-ids $instance_id \
            --region eu-central-1 \
            --query 'Reservations[0].Instances[0].Placement.AvailabilityZone' \
            --output text 2>/dev/null)
        
        if [ -n "$az" ] && [ "$az" != "None" ] && [ "$az" != "null" ]; then
            echo "  Availability Zone: $az"
            
            # Add the topology label
            kubectl label node $node topology.ebs.csi.aws.com/zone=$az --overwrite
            
            # Also add the standard Kubernetes topology label for good measure
            kubectl label node $node topology.kubernetes.io/zone=$az --overwrite
            
            echo "  ✅ Added topology labels to $node"
        else
            echo "  ❌ Could not get AZ for instance $instance_id"
        fi
    else
        echo "  ❌ Could not get instance ID for node $node"
    fi
    echo ""
done

echo "4. Restart EBS CSI components to pick up changes..."
kubectl rollout restart daemonset ebs-csi-node -n kube-system
kubectl rollout restart deployment ebs-csi-controller -n kube-system

echo -e "\n5. Wait for EBS CSI pods to restart..."
sleep 15

echo -e "\n6. Verify topology labels are now present:"
kubectl get nodes -o custom-columns="NAME:.metadata.name,EBS_ZONE:.metadata.labels.topology\.ebs\.csi\.aws\.com/zone,K8S_ZONE:.metadata.labels.topology\.kubernetes\.io/zone"

echo -e "\n7. Check CSINodes now have topology information:"
kubectl get csinodes -o yaml | grep -A 10 topologyKeys

echo -e "\n8. Clean up stuck PVCs to force reprovisioning..."
kubectl delete pvc data-vhsm-0 data-vhsm-1 data-vhsm-2 test-storage -n emcp-dev --force

echo -e "\n9. Delete stuck pods to trigger rescheduling..."
kubectl delete pod vhsm-0 vhsm-1 vhsm-2 -n emcp-dev --force --grace-period=0

echo -e "\n10. Check if StatefulSet recreates pods with working PVCs..."
sleep 10
kubectl get pods -n emcp-dev
kubectl get pvc -n emcp-dev

echo -e "\n=== VERIFICATION ==="
echo "Wait 2 minutes then check:"
echo "kubectl get pvc -n emcp-dev"
echo "kubectl describe pvc data-vhsm-0 -n emcp-dev"
echo ""
echo "If PVCs are still failing, try switching to gp2 storage class:"
echo "kubectl patch statefulset vhsm -n emcp-dev -p '{\"spec\":{\"volumeClaimTemplates\":[{\"metadata\":{\"name\":\"data\"},\"spec\":{\"storageClassName\":\"gp2\"}}]}}'"