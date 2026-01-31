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

## Part 2: Graceful Operational Handling

### 1. Health Check Endpoint
Implemented a `/health` endpoint that:
- Checks Apache web server status
- Returns HTTP 200 if healthy, 503 if unhealthy
- Includes system information (timestamp, hostname)
- Configured in Apache using CGI scripts

### 2. Auto Scaling Group with Graceful Handling
Created an Auto Scaling Group with:
- **Launch Template**: Pre-configured AMI with web server and health check
- **Minimum 2 instances**: For redundancy and high availability
- **Lifecycle Hook**: `graceful-shutdown-hook` for instance termination
- **Target Group**: Connected to Application Load Balancer

### 3. Application Load Balancer
Deployed an ALB that:
- Distributes traffic across multiple instances
- Uses `/health` endpoint for health checks
- Security groups restrict direct instance access (only from ALB)

### Graceful Shutdown Process
When an instance needs to be terminated (scale-in or replacement):
1. **Lifecycle Hook Triggered**: Auto Scaling sends termination notification
2. **Graceful Period**: Instance enters "Terminating:Wait" state (300 seconds)
3. **Shutdown Script Executes**:
   - Waits 10 seconds for in-flight requests to complete
   - Stops Apache web server gracefully
   - Signals lifecycle hook completion
4. **Instance Terminated**: Auto Scaling completes termination after receiving signal

This ensures:
- No dropped user requests during scale-in
- Clean application shutdown
- Proper deregistration from load balancer

### Security Configuration
- **Web instances**: Only accept HTTP traffic from Load Balancer security group
- **Load Balancer**: Accepts HTTP from internet, forwards to instances
- **SSH access**: Still allowed for troubleshooting

### Graceful Shutdown Process Description

The graceful shutdown process ensures that when Auto Scaling needs to terminate an instance (during scale-in or instance refresh), it doesn't abruptly cut off user requests. 

When termination begins: 
1) Auto Scaling triggers a lifecycle hook that pauses termination for 300 seconds. 
2) The instance runs a shutdown script that waits 10 seconds for in-flight requests to complete. 
3) Apache web server is stopped gracefully using `systemctl stop httpd`. 
4) The script signals the lifecycle hook that shutdown is complete. 
5) Auto Scaling proceeds with termination.

This process prevents "request dropped" errors for users and allows the application to clean up resources properly. The load balancer automatically detects the instance is unhealthy (via health checks) and stops sending new traffic during the shutdown process.

The implementation uses AWS lifecycle hooks, custom scripts, and coordinated timing to ensure smooth operations during scaling events.
