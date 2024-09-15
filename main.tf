terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "mybucket"
    key    = "path/to/my/key"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
#Creating the VPC using module
module "my_vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = var.vpc_name
  cidr = var.cidr
  azs             = var.avilability_zone
  public_subnets  = var.public_subnets
  tags = {
    Terraform = "true"
    Environment = "UAT" 
  }
}
/*
#Cloudwatch using modules
module "log_metric_filter" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter"
  version = "~> 3.0"

  log_group_name = var.log_group_name
  log_group_retention_in_days = var.retention_in_days
  log_stream_name = var.stream_name
  alarm_name = var.alarm_name
  alarm_comparison_operator = var.alarm_comparison_operator
  alarm_evaluation_periods  = var.alarm_evaluation_periods
  alarm_threshold           = var.alarm_threshold
  alarm_period              = var.alarm_period
  alarm_namespace   = var.alarm_namespace
  alarm_metric_name = var.alarm_metric_name
  alarm_statistic   = var.alarm_statistic
  instance_id = var.instance_id
  sns_topic_name = var.sns_topic_name
  
}
*/

resource "aws_instance" "jenkins_server" {
  ami           = "${data.aws_ami.linux.id}"
  instance_type = "t2.micro"
  subnet_id     = module.my_vpc.public_subnets[0] # Using the first subnet
  associate_public_ip_address = true
  security_groups = [aws_security_group.ec2_sg.id]
  #key_name = var.key_name  -- created pem file usgin terraform
  key_name = "sonar.pem"
  tags = {
    Name = "Jakins_server"
  }
}

# Creating pem file using terraform
/*
resource "tls_private_key" "rsa-4096_pem_file" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
# Creating key pair. 
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa-4096_pem_file.public_key_openssh
}

resource "local_file" "private_key" {
  content = tls_private_key.rsa-4096_pem_file.private_key_pem
  filename = var.key_name
}
*/

data "aws_ami" "linux" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name   = "name"
    values = ["al2023-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "Architecture-type"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = module.my_vpc.id 

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = module.my_vpc.cidr
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = module.my_vpc.cidr
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = module.my_vpc.cidr
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = module.my_vpc.cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = module.my_vpc.cidr
  from_port         = 9000
  ip_protocol       = "tcp"
  to_port           = 9000
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}



module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "s3-bucket_CD1"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }
}

