variable "type_instance" {
  default = {
    "dev"     = "t2.micro"
    "staging" = "t2.small"
    "prod"    = "t3.medium"
  }
  description = "it will be defined by environment, i.e. 'dev', 'prod', 'stage'"
}


variable "project_name" {
  description = "example to use terraform.tfvars"
}
