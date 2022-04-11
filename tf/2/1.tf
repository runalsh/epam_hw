terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  access_key = "AKIARGGSS3MVYT562XHM"
  secret_key = "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"
}

#####################################################  VARS 
variable "db_name" {
  default = "dbname"
}

variable "db_user" {
  default = "dbadmin"
}

variable "db_password" {
  default = "dbpassword"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

################## VPC and SG

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "sg_main" {
  name   = "aws-sec-group-main"
   dynamic "ingress" {
      for_each = ["22","80"]
    content {
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
}
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "sg_main_db" {
  name   = "aws-sec-group-main-db"
   dynamic "ingress" {
      for_each = ["3306"]
    content {
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
}
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

#======= template ===============

data "template_file" "cloudinit_main" {
  template = file("./ci.yml")
}

data "template_cloudinit_config" "cloudinit_config" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "./ci.yml"
    content_type = "text/cloud-config"
    content      = data.template_file.cloudinit_main.rendered
  }
}


#####################################################  instance

resource "aws_instance" "wp_instance" {
  ami                     = data.aws_ami.amazon_linux.id
  instance_type           = var.instance_type
 security_groups = [ aws_security_group.sg_main.name ] 
## 	user_data = data.template_cloudinit_config.cloudinit_config.rendered

  lifecycle {
    create_before_destroy = true
  }
} 

#####################################################  DB
resource "aws_db_instance" "db" {
  identifier = "db"
  engine = "mysql"
  engine_version = "8.0.28"
  allocated_storage = 5
  instance_class = "db.t2.micro"
  name = var.db_name
  username = var.db_user
  password = var.db_password 
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.sg_main_db.id]
}


#####################################################  OUTPUT

output "public_ip" {
  value       = aws_instance.wp_instance.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.db.endpoint
}