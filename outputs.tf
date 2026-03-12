output "transit_gateway_id" {
  description = "L'ID del Transit Gateway centrale (l'hub della nostra architettura)"
  value       = aws_ec2_transit_gateway.this.id
}

output "inspection_vpc_id" {
  description = "L'ID della Inspection VPC"
  value       = module.inspection_vpc.vpc_id
}

output "inspection_alb_dns_name" {
  description = "Il DNS Name pubblico dell'Application Load Balancer"
  value       = module.inspection_vpc.alb_dns_name
}