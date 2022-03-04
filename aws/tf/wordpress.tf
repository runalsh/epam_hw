#==== prov ======================

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

#===== variables =================

variable "region" {
  default = "eu-central-1"
}

variable "public_subnets" {
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "key_name" {
  type    = string
  default = "grdgd678grgegee"
}

variable "db_name" {
  default = "wp_db"
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

#========== S3 ==============

/* resource "aws_s3_bucket" "terraform_state" {
  bucket = "statebucket-my-for-epam"
  lifecycle {
    prevent_destroy = true
  }
} */

terraform {
  backend "s3" {
    bucket = "statebucket-my-for-epam"
    key    = "statebucket-my-for-epam/terraform.tfstate"
    region = "eu-central-1"
  }
}

#============ RES ==========

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
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


#========== perm ============


resource "aws_iam_instance_profile" "ecs_service_role" {
  role = aws_iam_role.ecs-instance-role.name
}


resource "aws_iam_role" "ecs-instance-role" {
  name = "ecs-instance-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

#========== VPC =======================

resource "aws_internet_gateway" "igw_main" {
  vpc_id = aws_vpc.vpc_main.id
}

resource "aws_security_group" "sg_main" {
  name   = "aws-sec-group-main"
  vpc_id = aws_vpc.vpc_main.id 
  
  
   dynamic "ingress" {
      for_each = ["22","80","443"]
    content {
      from_port        = ingress.value
      to_port          = ingress.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }
}

  # ingress {
    # cidr_blocks = ["0.0.0.0/0"]
    # from_port   = 0
    # protocol    = "-1"
    # to_port     = 0
  # }

  # ingress {
    # cidr_blocks = ["0.0.0.0/0"]
    # from_port   = 80
    # protocol    = "tcp"
    # to_port     = 80
  # }
   # ingress {
    # cidr_blocks = ["0.0.0.0/0"]
    # from_port   = 22
    # protocol    = "tcp"
    # to_port     = 22
  # }
  # пусть будет иначе за LB нет соединения 
  # TODO создать для LB свою SG
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_availability_zones" "aviable_zones" {
  state                   = "available"
}

resource "aws_subnet" "subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.vpc_main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.aviable_zones.names[count.index]
  map_public_ip_on_launch = "true"
}

resource "aws_vpc" "vpc_main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_route_table" "vpc_route" {
  vpc_id = aws_vpc.vpc_main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_main.id
  }
}

resource "aws_route_table_association" "vpc_route_assoc" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.subnets[count.index].id
  route_table_id = aws_route_table.vpc_route.id
}

resource "aws_db_subnet_group" "sub_db_sg" {
  name       = "subnet-db-sg"
  subnet_ids = [aws_subnet.subnets.0.id, aws_subnet.subnets.1.id]
}

#========== LB ===================
resource "aws_lb" "web" {
  name                       = "load-balancer"
  load_balancer_type         = "application"
  subnets                    = aws_subnet.subnets.*.id
  security_groups            = [aws_security_group.sg_main.id]
  enable_deletion_protection = false
  internal           = false
}

resource "aws_lb_target_group" "lb_tg" {
  name        = "load-balancer-tg"
  port        = "80"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc_main.id
  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 2
    interval            = 10
    matcher             = "200"
  }
}


resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

#========== ELB sg=================
resource "aws_security_group" "elb_sg" {
  name = "elb_sg"
  vpc_id = aws_vpc.vpc_main.id

   # dynamic "ingress" {
      # for_each = ["80","443","8080"]
    # content {
      # from_port        = ingress.value
      # to_port          = ingress.value
      # protocol         = "tcp"
      # cidr_blocks      = ["0.0.0.0/0"]
  # }
# } 

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  egress = [
    {
    description = "Allow all outgoing traffic."
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false      
    }
  ]
}

#=======EFS==========
resource "aws_efs_file_system" "efs" {
	tags = {
     Name = "efs_mount_point"
    }
  }

resource "aws_efs_mount_target" "efs_mount" {
  count = length(var.public_subnets)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = "${element(aws_subnet.subnets.*.id, count.index)}"
  security_groups = [aws_security_group.efs_sg.id]
  }

#==========EFS sg=================
resource "aws_security_group" "efs_sg" {
  name = "efs_sg"
  vpc_id = aws_vpc.vpc_main.id

  ingress = [
    {
      description = "Allow private NFS."
      from_port = 2049
      to_port = 2049
      protocol = "tcp"
      cidr_blocks = [aws_vpc.vpc_main.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  egress = [
    {
    description = "Allow all outgoing private traffic."
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false      
    }
  ]
}



#====DB=============
resource "aws_db_instance" "db" {
  identifier = "db"
  engine = "mysql"
  engine_version = "8.0.28"
  allocated_storage = 20
  instance_class = "db.t2.micro"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  # availability_zone = "eu-central-1a" 
  db_subnet_group_name = aws_db_subnet_group.sub_db_sg.id
  name = var.db_name
  username = var.db_user
  # password = data.aws_ssm_parameter.rds-pass.value
  password = var.db_password 
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot = true
  depends_on = [aws_efs_file_system.efs]
}

#========RDS==============================

resource "random_string" "rds_password" {
  length           = 15
  special          = true
  override_special = "!#&"
  # keepers = {
    # kepeer1 = var.db_password
  # } 
}

resource "aws_ssm_parameter" "rds_password" {
  name        = "rds-ssm"
  description = "Admin password for MySQL"
  type        = "SecureString"
  value       = random_string.rds_password.result
}

data "aws_ssm_parameter" "rds-pass" {
  name       = "rds-ssm"
  depends_on = [aws_ssm_parameter.rds_password]
}

#==========DB sg========================
resource "aws_security_group" "db_sg" {
  name = "db_sg"
  vpc_id = aws_vpc.vpc_main.id

  ingress = [
    {
      description = "Allow private SQL."
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      cidr_blocks = [aws_vpc.vpc_main.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  ]

  egress = [
    {
    description = "Allow all outgoing private traffic."
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [aws_vpc.vpc_main.cidr_block]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    self = false      
    }
  ]
}

#======= template ===============

data "template_file" "cloudinit_main" {
  template = file("./ci.yml")
  vars = {
    "efs_ip" = "${aws_efs_file_system.efs.dns_name}"
    "db_name" = "${var.db_name}"
    "db_user" = "${var.db_user}"
    "db_password" = "${var.db_password}"
    "db_host" = "${aws_db_instance.db.address}"
  }
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



#=======scale=======================
resource "aws_launch_configuration" "launcher" {
  name_prefix   = "launcher-"
  associate_public_ip_address = true
  enable_monitoring           = true
  image_id                    = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ecs_service_role.arn
  key_name             = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.sg_main.id]
  user_data = data.template_cloudinit_config.cloudinit_config.rendered
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscale_group" {
  name                      = "autoscale_group-${aws_launch_configuration.launcher.name}"
  default_cooldown        = 300
  desired_capacity        = 2
  health_check_grace_period = 10
  target_group_arns     = [aws_lb_target_group.lb_tg.arn]
  health_check_type       = "ELB"
  launch_configuration    = aws_launch_configuration.launcher.id
  max_size                = 4
  metrics_granularity     = "2Minute"
  min_size                = 0
  vpc_zone_identifier       = aws_subnet.subnets.*.id
  depends_on                = [aws_db_instance.db, aws_efs_file_system.efs]
  # service_linked_role_arn = aws_iam_role.awsserviceroleforautoscaling.arn
  protect_from_scale_in = true
  lifecycle {
    create_before_destroy = true
  }
} 



# #=========  hren ======================
# resource "aws_instance" "wp_instance" {
  # ami                     = data.aws_ami.amazon_linux.id
  # instance_type           = var.instance_type
  # count          = length(var.public_subnets)
  # subnet_id      = aws_subnet.subnets[count.index].id
  # vpc_security_group_ids  = [aws_security_group.sg_main.id]
# #key_name                = var.key_name
  # key_name                = aws_key_pair.generated_key.key_name
  # depends_on = [aws_db_instance.db, aws_efs_file_system.efs]
  # user_data = data.template_cloudinit_config.cloudinit_config.rendered
  # lifecycle {
    # create_before_destroy = true
  # }
# }  



 
#================SHOWMEWHATYOUHAVE===================

output "alb_dns" {
  value = aws_lb.web.dns_name
}
