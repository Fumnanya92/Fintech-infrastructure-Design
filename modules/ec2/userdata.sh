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