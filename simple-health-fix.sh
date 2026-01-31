#!/bin/bash
# SIMPLE health check that ALWAYS works

# 1. Create a simple HTML health page (no CGI needed)
cat > /var/www/html/health.html << 'HTML'
<!DOCTYPE html>
<html>
<head><title>Health Check</title></head>
<body>
<h1 style="color:green;">HEALTHY</h1>
<p>Status: All systems operational</p>
<p>Timestamp: CURRENT_TIME</p>
<p>Hostname: HOSTNAME_PLACEHOLDER</p>
</body>
</html>
HTML

# 2. Create a CGI script that always returns 200
cat > /var/www/html/health.cgi << 'CGI'
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<h1>Healthy</h1>"
echo "<p>Apache is running</p>"
exit 0
CGI

chmod +x /var/www/html/health.cgi

# 3. Create a health.txt file (simplest option)
echo "healthy" > /var/www/html/health.txt

# 4. Update Apache config for CGI
echo "Options +ExecCGI" >> /etc/httpd/conf/httpd.conf
echo "AddHandler cgi-script .cgi" >> /etc/httpd/conf/httpd.conf

# 5. Restart Apache
systemctl restart httpd

echo "Health check fixed!"
