# Fintech Infrastructure Setup Documentation

## Overview
This document outlines the setup and configuration of the Fintech infrastructure using Terraform. It includes key details for reference and future modifications, as well as instructions for running Terraform commands.

---

## Infrastructure Components
1. **VPC**
   - Includes public and private subnets, route tables, and an internet gateway.

2. **Security Groups**
   - **ALB Security Group:** Allows inbound traffic on HTTP (80) and HTTPS (443).
   - **Fintech Security Group:** Restricts access to EC2 and RDS instances.

3. **Application Load Balancer (ALB)**
   - Distributes traffic across EC2 instances.
   - Configured with a target group for health checks and forwarding rules.

4. **EC2 Instances**
   - Hosts the application.
   - Includes EFS mounting for shared file storage.

5. **EFS (Elastic File System)**
   - Provides shared storage for the application.

6. **RDS (Relational Database Service)**
   - MySQL database for backend storage.

---

## Terraform Setup

### Backend Configuration
The Terraform state is stored remotely in an S3 bucket for collaboration and disaster recovery. The backend configuration is as follows:

```hcl
terraform {
  backend "s3" {
    bucket         = "fintech-terraform-state-bucket"
    key            = "terraform/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "fintech-terraform-state-lock"
    encrypt        = true
  }
}
```

---

## Terraform Implementation for Fintech Infrastructure

We’ll proceed step by step, starting with the foundational components: **VPC, Subnets, and Networking**. After that, we’ll move to compute resources (EC2, Auto Scaling), databases, and other services.

### **Step 1: VPC, Subnets, and Networking**

Here’s the Terraform setup for creating a secure VPC and networking essentials:

---

### **Directory Structure**
Organize your files for modularity:
```
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   ├── ec2/
│   ├── rds/
│   ├── load_balancer/
```

---

### **1. VPC Module**
**File:** `modules/vpc/main.tf`

```hcl
# VPC
resource "aws_vpc" "fintech_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "fintech-vpc"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = var.public_subnet_1_cidr
  availability_zone = var.availability_zone_1
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = var.public_subnet_2_cidr
  availability_zone = var.availability_zone_2
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zone_1
  tags = {
    Name = "private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.fintech_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zone_2
  tags = {
    Name = "private-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fintech_vpc.id
  tags = {
    Name = "fintech-igw"
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fintech_vpc.id
  tags = {
    Name = "public-route-table"
  }
}

# Route for Internet Gateway in Public Route Table
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table (Main Route Table)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.fintech_vpc.id
  tags = {
    Name = "private-route-table"
  }
}
```

---

### **2. Variables for VPC**
**File:** `modules/vpc/variables.tf`

```hcl
variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_1_cidr" {
  type = string
}

variable "public_subnet_2_cidr" {
  type = string
}

variable "private_subnet_1_cidr" {
  type = string
}

variable "private_subnet_2_cidr" {
  type = string
}

variable "availability_zone_1" {
  type = string
}

variable "availability_zone_2" {
  type = string
}

```

---

### **3. Outputs for VPC**
**File:** `modules/vpc/outputs.tf`

```hcl
output "vpc_id" {
  value = aws_vpc.fintech_vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.fintech_vpc.cidr_block
}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnet_1.id, 
    aws_subnet.private_subnet_2.id]
}

output "public_subnet_1_id" {
    value = aws_subnet.public_subnet_1.id
}

output "public_subnet_2_id" {
    value = aws_subnet.public_subnet_2.id
}


output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

```

---

### **4. How to Integrate and Deploy**
**File:** `main.tf`

```hcl
module "vpc" {
  source = "./modules/vpc"

  aws_region            = var.aws_region
  vpc_cidr              = var.vpc_cidr
  public_subnet_1_cidr  = var.public_subnet_1_cidr
  public_subnet_2_cidr  = var.public_subnet_2_cidr
  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  availability_zone_1   = var.availability_zone_1
  availability_zone_2   = var.availability_zone_2
```

---

## Terraform Commands

### Initialize Terraform
Run the following command to initialize Terraform. This sets up the backend and downloads required provider plugins.

```bash
terraform init
```

### Validate Configuration
Use this command to check for syntax errors or invalid configurations:

```bash
terraform validate
```

### Plan Infrastructure (continued)
Run the following command to see what changes will be made without actually applying them:

```bash
terraform plan
```

### Apply Changes
To create the infrastructure, run:

```bash
terraform apply
```

Terraform will prompt you for confirmation before applying the plan. Enter `yes` to proceed.

---

### Destroy Infrastructure
If you need to tear down the infrastructure, use:

```bash
terraform destroy
```
---

## Next Steps
1. **EC2 Configuration**: Configure instances with proper user data scripts to mount EFS and host the application.
2. **ALB Setup**: Integrate EC2 instances with the Application Load Balancer.
3. **Database Connections**: Link the application to the RDS instance for data storage.
4. **Monitoring & Logging**: Set up CloudWatch logs and metrics for monitoring.

Let's create the configuration for the **EC2 Instances and Auto Scaling Group**. The steps include setting up the **Launch Template**, **Auto Scaling Group**, and **user data scripts** to initialize the instances for the fintech application. Here's how the setup will look:

---

### **Modules Structure**
- We'll add these files to the `modules/ec2/` directory:
  - `main.tf`: Define resources like `aws_launch_template` and `aws_autoscaling_group`.
  - `variables.tf`: Variables for instance type, AMI, key pair, and scaling configuration.
  - `outputs.tf`: Outputs for instance IDs and other relevant information.

---

### **Terraform Configuration**
#### `modules/ec2/main.tf`
```hcl
# Generate SSH Key Pair for EC2
resource "tls_private_key" "fintech" {
    algorithm = "RSA"
      rsa_bits  = 2048
}

resource "aws_key_pair" "fintech_keypair" {
    key_name   = var.key_name  # Use variable instead of hardcoded name
    public_key = tls_private_key.fintech.public_key_openssh
}

# Save the private key locally
resource "local_file" "techkey" {
    content  = tls_private_key.fintech.private_key_pem
    filename = "${var.key_name}.pem"  # Save the private key with dynamic filename
}

# Create Elastic IP for the instance (optional for public access)
resource "aws_eip" "fintech_eip" {
    domain = "vpc"  # Specifies that this is for use in a VPC
}


# EC2 Instance Configuration
resource "aws_instance" "fintech_instance" {
    ami                         = "ami-066a7fbea5161f451"  # Replace with appropriate AMI ID
    instance_type               = "t3.micro"
    key_name                    = aws_key_pair.fintech_keypair.key_name
    vpc_security_group_ids      = [var.security_group_id]
    subnet_id                   = var.subnet_id           # Use the passed subnet ID
    associate_public_ip_address = true                           # Associates a public IP

    # User data for EC2 instance configuration (e.g., EFS mounting)
    user_data = templatefile("${path.module}/userdata.sh", {efs_id = var.efs_id })

    tags = {
        Name = "fintech-instance"
     }
}

# Associate Elastic IP with the instance (optional for dedicated IP)
resource "aws_eip_association" "fintech_eip_association" {
    instance_id   = aws_instance.fintech_instance.id
      allocation_id = aws_eip.fintech_eip.id
}

```

---

#### `modules/ec2/variables.tf`
```hcl
#variable "subnet_ids" {
 # description = "The subnet IDs where the EC2 instance should be launched"
  #type        = list(string)  # Make sure it's a list of strings, not a single string
#}


variable "vpc_id" {
  description = "VPC ID where the EC2 instance will be launched."
  type        = string
}

variable "efs_id" {
  description = "The EFS ID to mount on EC2."
  type        = string
}

variable "db_endpoint" {
  description = "The RDS DB endpoint to connect to."
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to resources"
  type        = string
}

# ec2/variables.tf
variable "subnet_id" {
    description = "Subnet ID to launch the instance in"
      type        = string
}

variable "fintech_tg_arn" {
  description = "ARN of the target group for fintech instances"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for Auto Scaling Group"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}
```

---

#### `modules/ec2/outputs.tf`
```hcl
output "launch_template_id" {
  value = aws_launch_template.fintech_app_lt.id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.fintech_asg.name
}
```

---

#### `modules/ec2/userdata.sh`
```bash
#!/bin/bash
# Update packages
yum update -y

# Install necessary packages for EFS mounting
yum install -y amazon-efs-utils nfs-utils

# Create a directory to mount EFS
mkdir -p /var/www/html

# Mount EFS using the file system ID from Terraform
mount -t efs ${efs_id}:/ /var/www/html

# Make the mount persistent on reboot
echo "${efs_id}:/ /var/www/html efs defaults,_netdev 0 0" >> /etc/fstab

# Install Apache and PHP (if required for WordPress)
yum install -y httpd php

# Start and enable Apache on boot
systemctl start httpd
systemctl enable httpd

yum install -y docker
service docker start
usermod -a -G docker ec2-user

sudo rpm -Uvh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
sudo yum install mysql-community-server -y
sudo systemctl enable mysqld
sudo systemctl start mysqld

# Pull and run the fintech application container
docker pull <YOUR_DOCKER_IMAGE>
docker run -d -p 80:80 <YOUR_DOCKER_IMAGE>
```

---

### **Include the Module in the Root `main.tf`**
```hcl
# EC2 Module Configuration
module "ec2" {
  source            = "./modules/ec2"
  key_name          = var.key_name
  subnet_id         = module.vpc.public_subnet_1_id # Use public subnet 1 for EC2
  vpc_id            = module.vpc.vpc_id
  efs_id            = module.efs.efs_id
  db_endpoint       = module.rds.rds_endpoint
  security_group_id = aws_security_group.fintech_sg.id # Passing SG to module
  fintech_tg_arn    = module.alb.fintech_tg_arn        # Pass the target group ARN
  public_subnets    = module.vpc.public_subnet_ids     # Pass subnets here
}

```

---

### **Next Steps**
1. Update your `terraform.tfvars` file with:
   - AMI ID
   - Key pair name
2. Apply the configuration:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
3. Confirm the instances are created and scaled as per your configuration.

---

# **RDS Setup in Terraform**

## **Objective**
To set up an RDS instance using Terraform for a WordPress application, ensuring it is configured with the proper storage, security, and VPC setup.

---

## **Steps**

### 1. **Define Variables in `variables.tf`**

In `variables.tf`, define all the necessary variables required for the RDS instance setup, including storage size, engine version, instance class, and sensitive data like database username and password.

```hcl
variable "allocated_storage" {
  type        = number
  description = "The allocated storage for the RDS instance in GB"
  default     = 20
}

variable "engine_version" {
  type        = string
  description = "The MySQL engine version for the RDS instance"
  default     = "8.0"
}

variable "instance_class" {
  type        = string
  description = "The instance class for the RDS instance"
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The database name for WordPress"
  type        = string
  default     = "wordpress_db"
}

variable "db_username" {
  description = "The master username for the RDS instance"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "The master password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for RDS deployment"
}

variable "security_group_id" {
  description = "Security group ID to attach to resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where the RDS instance will be deployed"
  type        = string
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "Allowed CIDR blocks for access to RDS"
}
```

---

### 2. **Create RDS Instance and Subnet Group in `main.tf`**

In `modules/rds/main.tf`, create the `aws_db_instance` and `aws_db_subnet_group` resources to define the RDS instance configuration and the subnet group for the instance:

```hcl
resource "aws_db_instance" "fintech_rds" {
  allocated_storage      = var.allocated_storage
  engine                 = "mysql"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
}

resource "aws_db_subnet_group" "rds_subnet" {
  name       = "rds-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids = var.private_subnet_ids
}
```

---

### 3. **Set Up Outputs for RDS Endpoint**

In `modules/rds/outputs.tf`, define an output to capture the endpoint of the RDS instance:

```hcl
output "rds_endpoint" {
  value       = aws_db_instance.fintech_rds.endpoint
  description = "RDS instance endpoint"
}
```

---

### 4. **Configure the RDS Module in `main.tf`**

In your root `main.tf`, reference the RDS module and pass necessary values. Make sure to pass the `vpc_id`, `allocated_storage`, `db_name`, `db_username`, `db_password`, etc., as input variables.

```hcl
module "rds" {
  source              = "./modules/rds"
  vpc_id              = module.vpc.vpc_id
  allocated_storage   = var.allocated_storage
  engine_version      = var.engine_version
  instance_class      = var.instance_class
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  allowed_cidr_blocks = var.allowed_cidr_blocks
  private_subnet_ids  = var.private_subnet_ids
  security_group_id   = var.security_group_id
}
```

---

### 5. **Pass Values from `terraform.tfvars`**

In the `terraform.tfvars` file, provide values for all the variables declared in `variables.tf`. This file allows you to set the values for the variables:

```hcl
vpc_id              = "vpc-12345678"
allocated_storage   = 20
engine_version      = "8.0"
instance_class      = "db.t3.micro"
db_name             = "wordpress_db"
db_username         = "admin"
db_password         = "your_secure_password"
allowed_cidr_blocks = ["10.0.0.0/16"]
private_subnet_ids  = ["subnet-1234abcd", "subnet-5678efgh"]
security_group_id   = "sg-98765432"
```

---

### 6. **Apply the Terraform Configuration**

Once everything is configured, run the following Terraform commands to apply the changes:

1. Initialize the configuration:
   ```bash
   terraform init
   ```

2. Validate the configuration:
   ```bash
   terraform validate
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

   Review the plan and approve the changes to create the RDS instance.

---

### 7. **Verify the Deployment**

Once the `terraform apply` completes successfully, verify that the RDS instance is correctly deployed. Check the output `rds_endpoint` to get the endpoint for the database connection.

-
---
# Step 3: Implement PCI DSS Compliance

## **1. Encrypting Data at Rest**
### **Objective:**
Ensure that sensitive data stored in databases and file systems is encrypted to comply with PCI DSS requirements.

### **Actions Taken:**
#### **Amazon RDS Encryption**
- **Updated RDS Resource Configuration:**
  - Enabled encryption at rest for the Amazon RDS instance using AWS Key Management Service (KMS).
  - Configured `storage_encrypted = true` in the Terraform RDS resource.
  - Created and associated a KMS key specifically for RDS encryption.

#### **Amazon EFS Encryption**
- **Updated EFS Resource Configuration:**
  - Enabled encryption at rest for the Elastic File System (EFS).
  - Configured `encrypted = true` in the Terraform EFS resource.
  - Created and associated a KMS key specifically for EFS encryption.

### **Terraform Code Implemented:**
#### **RDS Resource**
```hcl
resource "aws_db_instance" "fintech_rds" {
  allocated_storage      = var.allocated_storage
  engine                 = "mysql"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false

  # Enable encryption at rest
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds_kms_key.arn

  # Attach the security group and subnet group
  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet.name
}

resource "aws_kms_key" "rds_kms_key" {
  description             = "KMS key for encrypting RDS instance"
  deletion_window_in_days = 7
}

resource "aws_db_subnet_group" "rds_subnet" {
  name        = "rds-subnet-group"
  description = "Subnet group for RDS instance"
  subnet_ids  = var.private_subnet_ids
}
```

#### **EFS Resource**
```hcl
# EFS file system with encryption at rest
resource "aws_efs_file_system" "efs" {
  encrypted    = true
  kms_key_id   = aws_kms_key.efs_kms_key.arn

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name = "fintech-efs"
  }
}

# KMS key for EFS encryption
resource "aws_kms_key" "efs_kms_key" {
  description             = "KMS key for encrypting EFS file system"
  deletion_window_in_days = 7
}

# EFS Mount Target for each private subnet
resource "aws_efs_mount_target" "efs_mount_target" {
  count            = length(var.subnet_ids)
  file_system_id   = aws_efs_file_system.efs.id
  subnet_id        = var.subnet_ids[count.index]
  security_groups  = [var.security_group_id]
}
```

### **Results:**
- Data stored in RDS and EFS is now encrypted at rest using AWS KMS.
- Verified encryption settings in the AWS Management Console and CLI.

---

## Phase 2: IAM Roles and Access Control

## Overview
In this phase, we configure AWS Identity and Access Management (IAM) roles, users, and policies to secure and control access to AWS resources. This includes creating IAM users, roles, and attaching the necessary policies to ensure that only authorized entities can access and manage the infrastructure components.

## Objectives
- **Create IAM Users** for specific tasks such as accessing S3 buckets or managing EC2 instances.
- **Attach Policies to IAM Users and Roles** to define permissions and security boundaries.
- **Control S3 Bucket Access** by limiting access to specific IAM users.

## Key Components
1. **IAM User for S3 Access**:  
   Create an IAM user with permissions to access specific S3 buckets for secure file management.

2. **IAM Role for EC2**:  
   Create an IAM role to be used by EC2 instances to interact with other AWS services like ECS, RDS, etc.

3. **IAM Policy Attachments**:  
   Attach appropriate IAM policies to the users and roles to enforce the principle of least privilege.

---

## Steps

### Step 1: Create IAM User

1. **Create an IAM User** for S3 bucket access:
   - The user will be granted permissions to read and write to the designated S3 bucket.
   - IAM user creation is handled in `main.tf` using the `aws_iam_user` resource.

   ```hcl
   resource "aws_iam_user" "fintech_user" {
     name = "fintech-user"

     tags = {
       Name        = "fintech-user"
       Environment = var.environment
       Project     = var.project_name
     }
   }
   ```

2. **Attach a Policy** to the IAM user:
   - The `AmazonS3FullAccess` policy is attached to the user to grant full access to S3 resources.

   ```hcl
   resource "aws_iam_user_policy_attachment" "fintech_user_s3_access" {
     user       = aws_iam_user.fintech_user.name
     policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
   }
   ```

---

### Step 2: Update S3 Bucket Policy

1. **Modify the S3 bucket policy** to allow access for the created IAM user.
   - The policy grants the IAM user permission to perform actions like `s3:GetObject`, `s3:PutObject`, and `s3:ListBucket`.

   ```hcl
   resource "aws_s3_bucket_policy" "fintech_bucket_policy" {
     bucket = module.s3.s3_bucket_name

     policy = <<EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:ListBucket"
         ],
         "Principal": {
           "AWS": "${aws_iam_user.fintech_user.arn}"
         },
         "Resource": [
           "arn:aws:s3:::${module.s3.s3_bucket_name}",
           "arn:aws:s3:::${module.s3.s3_bucket_name}/*"
         ]
       }
     ]
   }
   EOF
   }
   ```

   - This policy restricts access to the specific IAM user (`fintech-user`) and ensures that only authorized entities can interact with the S3 bucket.

---

### Step 3: Create IAM Role for EC2 Access

1. **Create an IAM Role** for EC2 instances to interact with AWS services:
   - This role will be assumed by EC2 instances to interact with other services, like ECS.

   ```hcl
   resource "aws_iam_role" "ec2_role" {
     name = "ec2-fintech-role"

     assume_role_policy = <<EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Action": "sts:AssumeRole",
         "Principal": {
           "Service": "ec2.amazonaws.com"
         },
         "Effect": "Allow"
       }
     ]
   }
   EOF
   }

   ```

2. **Attach Policies to the IAM Role**:
   - Policies such as `AmazonEC2FullAccess` can be attached to this role to allow EC2 instances to perform necessary actions on the infrastructure.

   ```hcl
  
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
   ```

---

### Step 4: (Optional) Additional IAM Role for ALB Access

1. **Create an IAM Role for Application Load Balancer (ALB)**:
   - If required, an IAM role can be created for the ALB to allow it to interact with other AWS services.

   ```hcl
   resource "aws_iam_role" "alb_role" {
     name = "alb-fintech-role"

     assume_role_policy = <<EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Action": "sts:AssumeRole",
         "Principal": {
           "Service": "elasticloadbalancing.amazonaws.com"
         },
         "Effect": "Allow"
       }
     ]
   }
   EOF
   }
   ```

## Summary
Phase 2 of the project focused on securing access to AWS resources by creating IAM users and roles and assigning appropriate permissions. The key steps involved:
- Creating IAM users with access to S3 resources.
- Attaching policies to the users and roles to grant the necessary permissions.
- Updating S3 bucket policies to restrict access to specific IAM users.


4. **Enable MFA for Users**
   - **Enforce MFA**: Ensure that all users accessing AWS resources via IAM have Multi-Factor Authentication (MFA) enabled for added security.

5. **Tag IAM Resources**
   - **Tagging**: Assign tags to IAM resources (roles, policies, users, etc.) for better visibility and management. Example tags:
     ```hcl
     tags = {
       "Environment" = "Production"
       "Project"     = "FinTech-Infrastructure"
     }
     ```

6. **Audit IAM Permissions**
   - **Review permissions**: Use **AWS IAM Access Analyzer** or **AWS Trusted Advisor** to regularly review and refine IAM permissions. This will help identify over-permissioned resources and improve security posture.

---

### Detailed Steps for IAM Role Setup and MFA Enforcement

#### 1. **Creating the `AdminGroup` IAM Group**

To create a new IAM group for enforcing MFA, add the following resource to your Terraform configuration:

```hcl
resource "aws_iam_group" "admin_group" {
  name = "AdminGroup"

  tags = {
    Environment = "Production"
    Project     = "FinTech-Infrastructure"
  }
}
```

This creates a new group named `AdminGroup` with the specified tags.

#### 2. **Attaching the MFA Enforcement Policy**

Attach the MFA enforcement policy to the newly created `AdminGroup` (or an existing group) using the following configuration. Here’s an example of attaching the policy to the newly created group:

```hcl
resource "aws_iam_group_policy_attachment" "mfa_enforcement_attachment" {
  group      = aws_iam_group.admin_group.name  # Reference the created group
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}
```

Alternatively, if you're using an existing group like `Admins`, modify the configuration like so:

```hcl
resource "aws_iam_group_policy_attachment" "mfa_enforcement_attachment" {
  group      = "Admins"  # Use the name of your existing IAM group
  policy_arn = aws_iam_policy.mfa_enforcement.arn
}
```

#### 3. **Creating IAM Policies for Services**

- **EC2 Instance Role Policy**: Create policies allowing EC2 instances to interact with other services like S3, EFS, and RDS.
- **RDS Access Policy**: Create policies to allow the necessary applications to connect to RDS.
- **CloudWatch Logging Policy**: Set up policies that grant logging permissions to CloudWatch for monitoring purposes.

#### 4. **Regular IAM Audits**

Use **IAM Access Analyzer** and **Trusted Advisor** to audit and refine IAM roles and policies periodically. This ensures that users and services only have the permissions they need, improving overall security.

---

### Conclusion

Implementing **IAM roles and policies** is a crucial step for securing the AWS infrastructure and maintaining compliance with **PCI DSS**. By ensuring **least privilege access**, using **MFA** for users, and regularly auditing IAM resources, the security and scalability of the infrastructure are enhanced.

---



