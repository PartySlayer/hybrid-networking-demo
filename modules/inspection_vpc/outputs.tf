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