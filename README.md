# SYST53364 - Lab 3: Resilient AWS Infrastructure

## Part 1: Infrastructure as Code

### Tool Choice: Terraform
I chose Terraform because it supports multiple cloud providers, has a readable configuration language (HCL), and strong community support.

### Configuration Layers:
1. **main.tf** - Infrastructure definition
2. **variables.tf** - Variable declarations
3. **terraform.tfvars** - Default configuration
4. **dev.tfvars** - Development overrides

### Secret Management:
Using AWS Secrets Manager to store database credentials securely.

## Configuration Management Approach (200-300 words)

This lab implements a layered configuration management approach using Terraform as Infrastructure as Code (IaC). The configuration is separated into four distinct layers:

1. **Infrastructure Code Layer** (`main.tf`): Contains declarative definitions of all AWS resources including VPC, subnets, EC2 instance, and security groups. This layer defines WHAT should be created without hardcoding environment-specific values.

2. **Variable Declaration Layer** (`variables.tf`): Defines all configurable parameters with type safety and default values. This provides a clear contract for what can be customized.

3. **Default Configuration Layer** (`terraform.tfvars`): Contains sensible defaults for all environments, such as t2.micro instance type and us-east-1 region. This serves as the baseline configuration.

4. **Environment-Specific Layer** (`dev.tfvars`): Overrides default values for specific environments. For development, we use t2.small instances. Different files can be created for staging/production.

5. **Secret Management Layer** (AWS Secrets Manager): Database credentials are stored securely outside version control. The EC2 instance retrieves secrets at runtime using IAM roles, ensuring no hardcoded credentials.

This approach provides several benefits: environment parity through consistent code, enhanced security through separated secrets, improved collaboration with clear separation of concerns, and easier debugging with transparent configuration layers.

The use of Terraform enables version-controlled infrastructure, repeatable deployments, and clear documentation through code.
