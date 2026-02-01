#!/bin/bash
# Remove duplicate aws_secretsmanager_secret_version from main.tf

# Create a clean version without the duplicate
grep -n "aws_secretsmanager_secret_version" main.tf

# The duplicate is in main.tf, we want to keep the one in rds.tf
# Let's comment out the one in main.tf
sed -i '/resource "aws_secretsmanager_secret_version" "db_secret"/,/^}/s/^/# /' main.tf

echo "Duplicate secret commented out in main.tf"
