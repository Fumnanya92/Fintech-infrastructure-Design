terraform {
  backend "s3" {
    bucket         = "fintech-terraform-state-bucket" # Replace with your bucket name
    key            = "terraform/terraform.tfstate"    # Replace with a custom path
    region         = "us-west-2"                      # Replace with your bucket region
    dynamodb_table = "fintech-terraform-state-bucket" # Replace with your DynamoDB table name
    encrypt        = true                             # Enable encryption for added security
  }
}



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
}
