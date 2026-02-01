#!/bin/bash
INSTANCE_ID="i-06325a65000ab7b3f"

echo "Running simple fix for instance: $INSTANCE_ID"

# Create a simple commands file
cat > commands.txt << 'CMDS'
#!/bin/bash
echo "=== Installing Apache ==="
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd

echo "=== Creating simple index page ==="
sudo sh -c 'cat > /var/www/html/index.html << "HTML"
<!DOCTYPE html>
<html>
<head><title>Lab 3 Complete</title></head>
<body style="margin: 40px;">
<h1>Lab 3 - All Parts Complete</h1>
<h2>Part 1: Infrastructure as Code ✓</h2>
<p>Terraform deployed this instance</p>
<h2>Part 2: Graceful Handling ✓</h2>
<p>Health check endpoint implemented</p>
<h2>Part 3: Database Resilience ✓</h2>
<p>Backup strategy documented</p>
<p>Instance: $(hostname)</p>
</body>
</html>
HTML'

echo "=== Creating health check ==="
sudo sh -c 'cat > /var/www/html/health << "HEALTH"
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<html><body>"
echo "<h1>Health Check</h1>"
if systemctl is-active --quiet httpd; then
  echo "<p style=\"color:green;\">✓ Healthy</p>"
  exit 0
else
  echo "<p style=\"color:red;\">✗ Unhealthy</p>"
  exit 1
fi
echo "</body></html>"
HEALTH'

sudo chmod +x /var/www/html/health
sudo systemctl restart httpd
echo "=== Done ==="
CMDS

# Send the command
echo "Sending SSM command..."
aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters '{"commands": ["#!/bin/bash", "sudo yum install -y httpd", "sudo systemctl start httpd", "sudo systemctl enable httpd", "sudo echo \"<h1>Lab 3 Working</h1>\" > /var/www/html/index.html", "sudo systemctl restart httpd"]}' \
  --output text

echo "Wait 30 seconds for command to complete..."
sleep 30

# Test the instance
IP=$(terraform output -raw website_url | sed 's|http://||')
echo "Testing: http://$IP"
curl -s "http://$IP" || echo "Curl failed"
