output "tgw_id" {
  description = "L'ID del Transit Gateway"
  value       = aws_ec2_transit_gateway.this.id
}

output "spoke_rt_id" {
  description = "L'ID della transit gateway RT dedicata alle vpc workload"
  value       = aws_ec2_transit_gateway_route_table.spoke_rt.id
}

output "inspection_rt_id" {
  description = "L'ID della transit gateway RT dedicata alla vpc inspection"
  value       = aws_ec2_transit_gateway_route_table.inspection_rt.id
}