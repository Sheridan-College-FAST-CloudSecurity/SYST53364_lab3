#!/bin/bash
# Graceful shutdown script for Auto Scaling lifecycle hook

# Set up logging
LOG_FILE="/var/log/graceful-shutdown.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== GRACEFUL SHUTDOWN STARTED at $(date) ==="

# Get instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
ASG_NAME=$(aws autoscaling describe-auto-scaling-instances \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --query "AutoScalingInstances[0].AutoScalingGroupName" \
  --output text)

echo "Instance ID: $INSTANCE_ID"
echo "Region: $REGION"
echo "Auto Scaling Group: $ASG_NAME"

# Step 1: Put instance in Draining state (stop accepting new connections)
echo "Step 1: Draining instance (simulated with sleep)..."
sleep 10  # Simulate waiting for in-flight requests

# Step 2: Stop Apache gracefully
echo "Step 2: Stopping Apache web server..."
systemctl stop httpd
sleep 5

# Step 3: Complete lifecycle hook (if in Auto Scaling termination)
# This would be called by the lifecycle hook, but we simulate it
echo "Step 3: Signaling lifecycle hook completion..."

# In real scenario, you would call:
# aws autoscaling complete-lifecycle-action \
#   --lifecycle-hook-name graceful-shutdown \
#   --auto-scaling-group-name "$ASG_NAME" \
#   --lifecycle-action-result CONTINUE \
#   --instance-id "$INSTANCE_ID" \
#   --region "$REGION"

echo "=== GRACEFUL SHUTDOWN COMPLETED at $(date) ==="

# Shutdown the instance (this would happen automatically after hook completes)
# shutdown -h now
