# Security Group for ALB
resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "fintech-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false
  idle_timeout               = 60

  tags = {
    Name = "fintech-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "fintech_tg" {
  name     = "fintech-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 3
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }
}

# Listener for HTTP
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fintech_tg.arn
  }
}

##########################
# ALB IAM Role (Optional)
##########################
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

# Attach AWS Managed Policy for ALB Access
resource "aws_iam_role_policy_attachment" "alb_role_policy_attachment" {
  role       = aws_iam_role.alb_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
