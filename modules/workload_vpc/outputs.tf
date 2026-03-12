output "vpc_id" {
  description = "L'ID della Workload VPC"
  value       = aws_vpc.this.id
}

output "app_subnet_id" {
  description = "L'ID della subnet applicativa"
  value       = aws_subnet.app.id
}