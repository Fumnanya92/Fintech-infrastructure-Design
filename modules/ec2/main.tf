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


##########################
# IAM Roles and Policies
##########################

# EC2 IAM Role
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
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Environment = "Production"
    Project     = "FinTech-Infrastructure"
  }
}

# EC2 IAM Policy
resource "aws_iam_policy" "ec2_policy" {
  name        = "ec2-fintech-policy"
  description = "Policy for EC2 to access S3, RDS, EFS, and CloudWatch"

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
      "Resource": [
        "arn:aws:s3:::${var.s3_bucket_name}",
        "arn:aws:s3:::${var.s3_bucket_name}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "rds:*",
        "logs:*",
        "cloudwatch:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach Policy to EC2 Role
resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-fintech-instance-profile"
  role = aws_iam_role.ec2_role.name
}
