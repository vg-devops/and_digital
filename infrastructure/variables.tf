variable "vpc_cidr" {
  default = "10.50.0.0/16"
}

variable "env" {
  default     = "dev"
  description = "Defines environment to deploy applications, development, production and staging: 'dev', 'prod', 'stage', - use exactly one of these words"
}


variable "region" {
  default     = "eu-west-1"
  description = "ensure the number of availability_zones to be 3 or more"
}

variable "project_name" {
  description = "any project name here"
}
