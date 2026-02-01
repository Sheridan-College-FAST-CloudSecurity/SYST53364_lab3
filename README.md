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

When our Auto Scaling Group needs to remove an instance (like during scale-in or updates), we use a graceful shutdown process to avoid interrupting users.
First, AWS triggers a "lifecycle hook" that pauses the termination for 5 minutes. During this time, the instance runs a custom shutdown script. This script waits 10 seconds to let any ongoing web requests finish, then gracefully stops the Apache web server.
Meanwhile, the load balancer notices the instance isn't responding to health checks anymore and stops sending new traffic to it. Only after the shutdown script completes does it signal AWS to continue with termination.
This approach prevents users from seeing "Connection Refused" errors because requests in progress get to finish, and new requests go to other healthy instances. It's like gently closing a store - you finish serving current customers but don't let new ones in, then lock up once everyone's done.
The implementation uses AWS lifecycle hooks combined with simple bash scripts to coordinate everything, ensuring our web application stays available during scaling events.

## Note on Part 3 (RDS):
Due to AWS Academy limitations with RDS creation, the RDS component is 
documented but not deployed. The configuration includes:

1. **RDS MySQL with Multi-AZ**: Terraform code is provided
2. **Backup Strategy**: 7-day automated backups
3. **Read Replica**: Configured for high availability
4. **Feature Toggle**: Database-driven feature management

The complete RDS Terraform configuration is available in the codebase,
but deployment was skipped to avoid AWS Academy resource limitations.

### Backup and Restore Strategy
Our database employs a dual-layered backup approach using Amazon RDS. First, automated daily backups retain data for 7 days, executing nightly at 3 AM to capture complete daily snapshots. Second, manual snapshots can be created on-demand before significant system changes or feature deployments. Recovery involves provisioning a new RDS instance from either backup type, with restoration typically completing within 15-20 minutes. This strategy ensures data protection against accidental deletions, corruption, or system failures, providing both scheduled protection and emergency recovery capabilities while maintaining a 7-day recovery window for point-in-time restoration.

### Database Failure Handling
The system gracefully manages database disruptions through automated failover and intelligent application logic. In RDS Multi-AZ configurations, AWS automatically promotes the standby replica during primary instance failures, typically within 1-2 minutes. During this transition, our web application implements a retry mechanism with three connection attempts spaced by brief intervals. If connectivity cannot be reestablished, the application displays user-friendly maintenance messages rather than technical error pages, maintaining user experience during outages. Additionally, CloudWatch alerts notify administrators of database issues, enabling prompt intervention while the system self-heals through AWS-managed failover processes.

### Feature Toggle Implementation
Feature toggles enable runtime feature management without application redeployment through a database-driven control system. A dedicated `feature_toggles` table stores feature states (e.g., 'new_dashboard': true/false), which the application queries on each request. This allows instant feature activation/deactivation via simple SQL updates, supporting A/B testing, gradual rollouts, and emergency rollbacks. For this lab, we implemented a dashboard toggle demonstrating how the same codebase can deliver different experiences based on database settings. This approach reduces deployment risks, enables controlled experimentation, and provides operational flexibility without code changes.

### Integrated Resilience
These components create a comprehensive resilience framework: automated backups safeguard data integrity, intelligent failure handling maintains service continuity, and feature toggles provide operational agility. Together, they ensure reliable system operation, rapid recovery from incidents, and safe feature evolution—key principles of resilient cloud infrastructure design.
