/*
----------------------------------------------------------
Terraform
Provisioning:
- VPC
- Internet Gateway
- 3 Public Subnets
- No Private Subnets (no 2nd or 3rd Tiers are required as per the project specification)
Prepared by Vagif Gafarov for AND DIGITAL

*/
#===================================================================================================================

provider "aws" {
  region = var.region
}

terraform {
  backend "s3" { #infra state is saved in this bucket
    bucket = "vg-devops-rs12345"
    key    = "infrastructure/terraform.tfstate"
    region = "eu-west-1"
  }
}

locals {
  public_subnet_cidrs = [cidrsubnet(var.vpc_cidr, 8, 0), cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
}


data "aws_availability_zones" "region_zones" {}

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name    = "VPC - ${var.env}"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "IGW - ${var.env}"
  }
}

#-------------Public Subnets and Routing----------------------------------------

resource "aws_subnet" "public_subnets" {
  count                   = length(local.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = element(local.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.region_zones.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name    = "${var.env}-pub_subnet-${count.index + 1}"
    Project = var.project_name
  }
}


resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name    = "${var.env}-route-public-subnets"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public_routes" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_routes.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}
