output "vpc_id" {
  description = "L'ID della Workload VPC"
  value       = aws_vpc.this.id
}

output "app_subnet_id" {
  description = "L'ID della subnet applicativa"
  value       = aws_subnet.app.id
}

output "tgw_attachment_id" {
  description = "L'ID dell'attachment del Transit Gateway"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}