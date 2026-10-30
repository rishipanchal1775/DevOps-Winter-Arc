#!/bin/bash

apt-get update -y
apt-get install -y nginx curl

TOKEN=$(curl -sS -X PUT \
  "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -sS \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

cat > /var/www/html/index.html <<EOF
<html>
<head><title>Day 29 HA Application</title></head>
<body>
  <h1>Highly Available Application</h1>
  <h2>Day 29 AWS Capstone</h2>
  <p>EC2 Instance ID: $INSTANCE_ID</p>
</body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx
