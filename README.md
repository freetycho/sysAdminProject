# System Administration Final Project Part 2
# Minecraft Server Automation on AWS

## Overview
This project automates the creation and configuration of a Minecraft server on AWS using Terraform. The infrastructure includes a VPC, subnet, security group, and an EC2 instance with the auto-start capabilities. The process to get started has been simplified to ensure an easy install, within 5 minutes of cloning the source repo, you should be up and running!

## Requirements

### Tools and Versions
- **Terraform** (v1.5.0 or later)  
- **AWS CLI** (v2.0 or later)  
- **Git** (for repository management)  

### Credentials
- AWS account with IAM permissions for EC2, VPC, and Elastic IP.  
- Configured AWS CLI credentials (`aws configure`).  

### Environment Variables
Ensure the following environment variables are set (or configure AWS CLI):  
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

## Pipeline Steps

### 1. Infrastructure Provisioning (Terraform)

-   **VPC, Subnet, and Internet Gateway**: Isolated network for the Minecraft server.
    
-   **Security Group**: Allows inbound traffic on port  `25565`  (Minecraft) and restricted SSH access.
    
-   **EC2 Instance**: Deploys a  `t4g.small`  instance with an auto-start script for the Minecraft server.
    
-   **Elastic IP**: Assigns a permenant public IP to the server.
    

### 2. Configuration (User Data Script)

-   Installs Java (Amazon Corretto 21).
    
-   Downloads the Minecraft server JAR and configures auto-start via  `systemd`.
    
-   Includes proper shutdown handling via custom scripts.
    

----------

## Usage

### 1. Clone the Repository

```bash
git clone https://github.com/freetycho/sysAdminProject
cd sysAdminProject
```
### 2. Initialize Terraform

```bash
terraform init
```
### 3. Deploy Infrastructure

```bash
terraform apply
```
After execution, Terraform will output the Minecraft server’s public IP (something like `minecraft_server_ip = 54.189.1.2`).

### 4. Verify Server Connectivity

```bash
nmap -sV -Pn -p T:25565 $(terraform output -raw minecraft_server_ip)
```

Expected output:

```plaintext 
25565/tcp open  minecraft
```

### 5. Connect to Minecraft

Use the output IP in your Minecraft client under  **Multiplayer**  >  **Direct Connect**.
The server will be available at the EIP, which is the IP printed in the console after running the terraform plan.