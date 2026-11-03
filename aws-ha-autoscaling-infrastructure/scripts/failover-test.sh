#!/usr/bin/env bash
# Demonstrates HIGH AVAILABILITY / SELF-HEALING.
# Terminates one instance on purpose. The website keeps working through the
# other instance, and the ASG automatically launches a replacement.
#
# Usage: ./scripts/failover-test.sh <alb-dns-name> [asg-name] [region]
set -euo pipefail

ALB_DNS="${1:?Pass the ALB DNS name (terraform output alb_dns_name)}"
ALB_DNS="${ALB_DNS#http://}"
ASG_NAME="${2:-ha-web-asg}"
REGION="${3:-ap-south-1}"

VICTIM=$(aws autoscaling describe-auto-scaling-groups \
  --region "$REGION" --auto-scaling-group-names "$ASG_NAME" \
  --query "AutoScalingGroups[0].Instances[0].InstanceId" --output text)

echo ">> Terminating instance ${VICTIM}"
aws ec2 terminate-instances --region "$REGION" --instance-ids "$VICTIM" >/dev/null

echo ">> Hitting the website every 2s - it should stay up the whole time (Ctrl+C to stop)"
while true; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${ALB_DNS}/health" || echo "000")
  COUNT=$(aws autoscaling describe-auto-scaling-groups --region "$REGION" \
    --auto-scaling-group-names "$ASG_NAME" \
    --query "length(AutoScalingGroups[0].Instances[?LifecycleState=='InService'])" --output text)
  echo "$(date +%H:%M:%S)  HTTP ${CODE}  in-service instances: ${COUNT}"
  sleep 2
done
