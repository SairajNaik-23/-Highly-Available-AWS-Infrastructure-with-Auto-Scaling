#!/usr/bin/env bash
# Demonstrates AUTO SCALING.
# Pushes CPU to 100% on every instance for 10 minutes using SSM Run Command
# (no SSH needed). Watch the ASG add instances, then remove them afterwards.
#
# Usage: ./scripts/cpu-stress-test.sh [asg-name] [region]
set -euo pipefail

ASG_NAME="${1:-ha-web-asg}"
REGION="${2:-ap-south-1}"

# 600 seconds of 100% CPU on every core (stress-ng, or a plain `yes` loop as fallback)
PARAMS='{"commands":["if command -v stress-ng >/dev/null; then stress-ng --cpu 0 --timeout 600s; else for i in $(seq $(nproc)); do timeout 600 yes > /dev/null & done; wait; fi"]}'

echo ">> Sending CPU stress command to all instances in ${ASG_NAME}"
aws ssm send-command \
  --region "$REGION" \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:aws:autoscaling:groupName,Values=${ASG_NAME}" \
  --comment "CPU stress test for auto scaling demo" \
  --parameters "$PARAMS" \
  --output text --query "Command.CommandId"

echo ">> Watching the ASG every 30s (Ctrl+C to stop)"
while true; do
  read -r DESIRED RUNNING < <(aws autoscaling describe-auto-scaling-groups \
    --region "$REGION" \
    --auto-scaling-group-names "$ASG_NAME" \
    --query "AutoScalingGroups[0].[DesiredCapacity, length(Instances)]" \
    --output text)
  echo "$(date +%H:%M:%S)  desired: ${DESIRED}  running: ${RUNNING}"
  sleep 30
done
