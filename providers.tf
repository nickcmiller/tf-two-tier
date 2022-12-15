# -- root/variables.tf -- 

#Declare the AWS provider
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Configure the AWS Provider with a variable in variables.tf
provider "aws" {
  region = var.aws_region
}