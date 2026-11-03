#!/bin/bash
# Runs once when each EC2 instance boots.
# Installs Apache and a page that shows WHICH instance / AZ served the request,
# so you can see the load balancer switching between instances.
set -euxo pipefail

dnf install -y httpd
dnf install -y stress-ng || echo "stress-ng not available - load test script will fall back to a CPU loop"

# IMDSv2: get a session token first, then read metadata
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Highly Available Web App</title></head>
<body style="font-family: Arial; text-align: center; margin-top: 80px;">
  <h1>Highly Available AWS Infrastructure</h1>
  <p>Served by instance: <b>${INSTANCE_ID}</b></p>
  <p>Availability Zone: <b>${AZ}</b></p>
  <p>Private IP: <b>${PRIVATE_IP}</b></p>
  <p>Refresh the page to see the load balancer switch instances.</p>
</body>
</html>
EOF

# Health check endpoint used by the ALB target group
echo "OK" > /var/www/html/health

systemctl enable --now httpd
