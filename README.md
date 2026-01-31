# SYST53364 - Lab 3: Resilient AWS Infrastructure

## Part 1: Infrastructure as Code

### Tool Choice: Terraform
Reason: Terraform is cloud-agnostic, supports multi-cloud deployments, and uses a declarative configuration language (HCL) that is human-readable. It also has a strong community and supports modular, reusable code.


### Configuration Layers:
1. **main.tf** - Infrastructure definition
2. **variables.tf** - Variable declarations
3. **terraform.tfvars** - Default configuration
4. **dev.tfvars** - Development overrides

### Secret Management:
Using AWS Secrets Manager to store database credentials securely.

## Configuration Management Approach

For this lab, I implemented a layered configuration management approach using Terraform to deploy AWS infrastructure. This method helps keep my code organized, reusable, and secure across different environments.

First, I created separate configuration layers to avoid hardcoding values. The main.tf file contains only the infrastructure definitions—like what resources to create (VPC, EC2 instance, security groups). Then I used variables.tf to declare all configurable parameters with default values. This separation means I can change settings without touching the main infrastructure code.

For environment-specific configurations, I created two files: terraform.tfvars for default values (like using t2.micro instances) and dev.tfvars for development overrides (like t2.small instances). This layered approach lets me deploy the same infrastructure to different environments just by switching configuration files, ensuring consistency while allowing flexibility.

For security, I used AWS Secrets Manager to handle sensitive data like database passwords. Instead of storing credentials in my code or Git repository (which would be unsafe), I configured Terraform to create a secret in AWS Secrets Manager. My application retrieves the password at runtime using IAM roles, so the actual secret never appears in my code.

This approach taught me the importance of separating configuration from code. It makes infrastructure more maintainable, secure, and adaptable to different needs. By using layered configuration and proper secret management, I can safely collaborate with others, track changes in Git, and deploy consistently across environments while following AWS best practices.
