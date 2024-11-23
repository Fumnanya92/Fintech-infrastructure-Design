# Launch Template for Fintech Instances
resource "aws_launch_template" "fintech_launch_template" {
  name_prefix   = "fintech-launch-template"
  image_id      = "ami-066a7fbea5161f451"  # Replace with your AMI ID
  instance_type = "t3.micro"

  key_name = aws_key_pair.fintech_keypair.key_name  # Assuming the key pair is available in the root module

  network_interfaces {
    security_groups = [var.security_group_id]  # Security group ID passed from the main module
    associate_public_ip_address = true         # Associates a public IP for the instances
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    efs_id = var.efs_id
  }))

  tags = {
    Name = "fintech-instance"
  }
}

# Auto Scaling Group for Fintech Instances
resource "aws_autoscaling_group" "fintech_asg" {
  desired_capacity        = 2                 # Adjust based on requirements
  max_size                = 3                 # Maximum number of instances
  min_size                = 1                 # Minimum number of instances

  launch_template {
    id      = aws_launch_template.fintech_launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier     = var.public_subnets  # List of public subnets from VPC

  target_group_arns       = [var.fintech_tg_arn]  # Target group ARN from ALB module
  health_check_type       = "ELB"                    # Use load balancer for health checks
  health_check_grace_period = 300                    # Grace period for instance health check

  tag {
    key                   = "Name"
    value                 = "fintech-instance"
    propagate_at_launch   = true
  }
}
