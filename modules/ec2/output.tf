output "public_ip" {
  value = aws_instance.fintech_instance.public_ip
}

# Outputs for the Auto Scaling Group
output "autoscaling_group_id" {
  value = aws_autoscaling_group.fintech_asg.id
}

output "launch_template_id" {
  value = aws_launch_template.fintech_launch_template.id
}
