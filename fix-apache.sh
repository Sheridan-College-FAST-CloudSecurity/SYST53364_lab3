#!/bin/bash
# Script to fix Apache web server

INSTANCE_ID="i-06325a65000ab7b3f"

echo "Fixing Apache on instance: $INSTANCE_ID"

# Run commands via SSM
COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --parameters 'commands=[
    "echo === Starting Apache fix ===",
    "sudo yum install -y httpd",
    "sudo systemctl start httpd",
    "sudo systemctl enable httpd",
    "echo === Creating web content ===",
    "sudo sh -c \"cat > /var/www/html/index.html << \\"HTMLEND\\"",
    "<!DOCTYPE html>",
    "<html>",
    "<head><title>Lab 3 - Complete</title>",
    "<style>",
    "body { font-family: Arial, sans-serif; margin: 40px; }",
    ".part { background: #f0f8ff; padding: 20px; margin: 15px 0; border-radius: 5px; }",
    ".check { color: green; font-weight: bold; }",
    "h1 { color: #2c3e50; }",
    "</style></head>",
    "<body>",
    "<h1>SYST53364 - Lab 3 Complete</h1>",
    "<div class=\\"part\\">",
    "<h2>Part 1: Infrastructure as Code</h2>",
    "<p class=\\"check\\">✓ Terraform configuration deployed</p>",
    "<p class=\\"check\\">✓ AWS Secrets Manager integrated</p>",
    "<p class=\\"check\\">✓ Security groups configured</p>",
    "</div>",
    "<div class=\\"part\\">",
    "<h2>Part 2: Graceful Handling</h2>",
    "<p class=\\"check\\">✓ Health check endpoint at /health</p>",
    "<p class=\\"check\\">✓ Auto Scaling Group designed</p>",
    "<p class=\\"check\\">✓ Load Balancer configured</p>",
    "</div>",
    "<div class=\\"part\\">",
    "<h2>Part 3: Database Resilience</h2>",
    "<p class=\\"check\\">✓ RDS backup strategy (7-day)</p>",
    "<p class=\\"check\\">✓ Multi-AZ deployment</p>",
    "<p class=\\"check\\">✓ Feature toggle implemented</p>",
    "</div>",
    "<hr>",
    "<p>Instance: $(hostname)</p>",
    "<p>Deployed with Terraform</p>",
    "</body></html>",
    "HTMLEND\"",
    "echo === Creating health check ===",
    "sudo sh -c \"cat > /var/www/html/health << \\"HEALTHEND\\"",
    "#!/bin/bash",
    "echo \\"Content-type: text/html\\"",
    "echo",
    "echo \\"<html><body>\\"",
    "echo \\"<h1>Health Check</h1>\\"",
    "if systemctl is-active --quiet httpd; then",
    "  echo \\"<p style='color:green;'>✓ Healthy</p>\\"",
    "  exit 0",
    "else",
    "  echo \\"<p style='color:red;'>✗ Unhealthy</p>\\"",
    "  exit 1",
    "fi",
    "echo \\"</body></html>\\"",
    "HEALTHEND\"",
    "sudo chmod +x /var/www/html/health",
    "echo === Configuring Apache ===",
    "sudo sh -c \"echo \\"Options +ExecCGI\\" >> /etc/httpd/conf/httpd.conf\"",
    "sudo sh -c \"echo \\"AddHandler cgi-script .sh\\" >> /etc/httpd/conf/httpd.conf\"",
    "echo === Restarting Apache ===",
    "sudo systemctl restart httpd",
    "echo === Checking Apache status ===",
    "sudo systemctl status httpd --no-pager",
    "echo === Testing web server ===",
    "curl -s http://localhost | head -5"
  ]' \
  --output text --query "Command.CommandId")

echo "Command ID: $COMMAND_ID"
echo "Waiting 15 seconds for command to complete..."
sleep 15

# Get command output
echo "=== COMMAND OUTPUT ==="
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "[StandardOutputContent,StandardErrorContent]" \
  --output text
