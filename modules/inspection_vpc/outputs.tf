output "vpc_id" {
  description = "L'ID della Inspection VPC"
  value       = aws_vpc.this.id
}

output "tgw_attach_subnet_id" {
  description = "L'ID della subnet dedicata all'attachment del TGW"
  value       = aws_subnet.tgw_attach.id
}

output "public_subnet_id" {
  description = "L'ID della public subnet (utile se in futuro vorrai deployare un ALB dal root module)"
  value       = aws_subnet.public.id
}

output "alb_dns_name" {
  description = "Il DNS Name pubblico del Load Balancer per accedere all'applicazione"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "L'ARN del Target Group (utile per agganciare istanze EC2 o servizi ECS)"
  value       = aws_lb_target_group.workload_tg.arn
}

output "tgw_attachment_id" {
  description = "L'ID dell'attachment del Transit Gateway"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}