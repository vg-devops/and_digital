/*
----------------------------------------------------------
Terraform
Provisioning:
- 2 x security_groups(for ELB and for instances)
- 1x elastic load balancer
- min 3 Instances, one in each subnet, created by the infrastructure module, by relevant autoscaling_groups and launch_configurations

Demonstrates:
- use of Lifecycle rules
- use of remote state created by another infra module
- use of functions
- use of template files for user_data


Prepared by Vagif Gafarov for AND DIGITAL

*/
#===================================================================================================================

provider "aws" {
  region = data.terraform_remote_state.infrastructure.outputs.vpc_region
}



terraform {
  backend "s3" {
    bucket = "vg-devops-rs12345" #resources state is saved in this bucket
    key    = "resources/terraform.tfstate"
    region = "eu-west-1"
  }
}

#====================================================================


data "terraform_remote_state" "infrastructure" {
  backend = "s3" #infra state is downloaded from this bucket
  config = {
    bucket = "vg-devops-rs12345"
    key    = "infrastructure/terraform.tfstate"
    region = "eu-west-1"
  }
}


data "aws_ami" "latest_ubuntu" { #finds latest Ubuntu image in any region
  owners      = ["099720109477"] #default value for Owner ID for AWS for all regions
  most_recent = true
  filter {
    name   = "name" # Actually, it is AMI Name in Amazon Console
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}


#===============================================================


resource "aws_security_group" "elb_security_group" {
  name   = "ELB Security Group"
  vpc_id = data.terraform_remote_state.infrastructure.outputs.vpc_id
  dynamic "ingress" { # 2 ports added for the future, http and https
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "ELB SecurityGroup"
    Owner = "Vagif Gafarov"
  }
}

resource "aws_security_group" "webserver_security_group" {
  name   = "WebServer Security Group"
  vpc_id = data.terraform_remote_state.infrastructure.outputs.vpc_id
  dynamic "ingress" { # 2 ports added for the future, http and https, working with http only for the time being
    for_each = ["80", "443"]
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.elb_security_group.id] # only accepts incoming connections from load balancer
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "WebServer Security Group"
    Owner = "Vagif Gafarov"
  }
}


resource "aws_launch_configuration" "web_lc" {
  name_prefix     = "Create_Before_Destroy_Launch_Config-" # with unique time stamp, also allow updating without destroying
  image_id        = data.aws_ami.latest_ubuntu.id
  instance_type   = lookup(var.type_instance, data.terraform_remote_state.infrastructure.outputs.vpc_environment)
  security_groups = [aws_security_group.webserver_security_group.id]
  user_data       = templatefile("user_data.sh.tpl", { project_name = var.project_name })

  lifecycle {
    create_before_destroy = true # almost zero downtime if config changes
  }
}



resource "aws_autoscaling_group" "web_autoscaling_group" {
  name                 = "ASG-${aws_launch_configuration.web_lc.name}"
  launch_configuration = aws_launch_configuration.web_lc.name
  min_size             = 3
  max_size             = 9
  min_elb_capacity     = 3
  health_check_type    = "ELB"
  vpc_zone_identifier  = data.terraform_remote_state.infrastructure.outputs.public_subnet_ids
  load_balancers       = [aws_elb.web_elb.name]

  dynamic "tag" {
    for_each = {
      Name  = "WebServer by AutoScaling"
      Owner = "Vagif Gafarov"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true # almost zero downtime if config changes
  }
}


resource "aws_elb" "web_elb" {
  name            = "WebServers-ELB"
  subnets         = data.terraform_remote_state.infrastructure.outputs.public_subnet_ids
  security_groups = [aws_security_group.elb_security_group.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "${data.terraform_remote_state.infrastructure.outputs.vpc_environment} - ELB"
  }
}
