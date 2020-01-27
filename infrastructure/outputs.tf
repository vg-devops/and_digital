output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.main_vpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "vpc_region" {
  value = var.region
}

output "number_of_subnets" {
  value = length(local.public_subnet_cidrs)
}

output "used_zone_names" {
  value = slice(data.aws_availability_zones.region_zones.names, 0, length(local.public_subnet_cidrs))
}

output "vpc_environment" {
  value = var.env
}
