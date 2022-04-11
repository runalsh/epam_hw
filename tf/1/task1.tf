terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_vpcs" "vpc_main" {
	default = true
}

data "aws_subnets" "subnets" {
}

data "aws_security_groups" "sec_groups" {
}

output "vpcs" {
	  description = "vpc id"
  value = data.aws_vpcs.vpc_main.ids
} 

output "subnets" {
  value = data.aws_subnets.subnets.ids
}

output "secgroups" {
  value = data.aws_security_groups.sec_groups.ids
}
