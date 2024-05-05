![alt text]([url-to-image.png](https://github.com/YashJain-ORG/tf-gcp-infra#:~:text=3%20months%20ago-,Cloud%20Architecture%20diagram%20.png,-Cloud%20Architecture%20diagram) "Optional title")

# Terraform Configuration for GCP Infrastructure

Welcome to our Terraform configuration repository dedicated to deploying and managing infrastructure on the Google Cloud Platform (GCP). This document provides comprehensive details about the activated services, current configurations, and management steps, along with insights from previous assignments.

## Services Activated on GCP

Our Terraform setup activates the following services on GCP:

- Compute Engine API
- Virtual Private Cloud (VPC)
- Firewall
- Service Networking API
- Cloud Build API
- Cloud Functions API
- Cloud Logging API
- Eventarc API
- Cloud Pub/Sub API
- Cloud Run Admin API

## Current Configuration

Here is a snapshot of our current Terraform configuration:

- **Region**: us-east1
- **Zone**: us-east1-b
- **IP CIDR Range for Web Application**: 69.4.21.0/24 transitions to 10.1.1.0/24
- **IP CIDR Range for Database**: 4.21.69.0/24 transitions to 10.2.1.0/24
- **Firewall Rules**: Allow traffic on port 6969
- **Compute Instance Custom Image**: `webapp-centos-stream-8-a4-v1-20269227204441`

## Steps to Manage Infrastructure

To manage your GCP infrastructure using Terraform, follow these steps:

1. **Initialize Terraform**:
   terraform init
This command initializes modules and prepares the working directory for other commands.

2. **Validate Configuration**:
   terraform validate
Ensures that the configuration is syntactically valid and internally consistent.

3. **Plan Infrastructure Changes**:   
   terraform plan
Displays an execution plan, showing Terraform's actions based on the current configuration.

4. **Apply Changes**:
Applies the changes required to reach the desired state of the configuration.

## Key Takeaways and Improvements

- **IP Range Consideration**: Proper selection of IP ranges is crucial for internal connectivity.
- **Network Segmentation**: Adjusted subnet configurations to prevent conflicts and enhance segmentation.
- **Connectivity Enhancements**: Implemented VPC peering and Serverless VPC connectors for better service integration.
- **Infrastructure Image Path Update**: Consistently updated the image path in configurations to avoid discrepancies.
- **Cloud SQL Instance Security**: Configured Cloud SQL instances with private IPs to enhance security.
- **Connectivity Options**: Utilized Private Service Access (PSA) and VPC peering for secure, private connections.
- **Private Service Connect (PSC)**: Set up PSC for private inter-service connectivity within the same VPC.
- **Firewall Tag Usage**: Applied firewall rules based on tags to refine network security protocols.

By continuously implementing these improvements and adhering to best practices, we aim to maintain a robust and secure infrastructure on the Google Cloud Platform.


      
