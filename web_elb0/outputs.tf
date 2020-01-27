output "web_loadbalancer_fqdn" {
  value = aws_elb.web_elb.dns_name
}
