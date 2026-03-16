output "tunnel1_address" {
  description = "Indirizzo IP pubblico del Tunnel 1 lato AWS"
  value       = aws_vpn_connection.this.tunnel1_address
}

output "tunnel2_address" {
  description = "Indirizzo IP pubblico del Tunnel 2 lato AWS"
  value       = aws_vpn_connection.this.tunnel2_address
}

output "tunnel1_preshared_key" {
  description = "PSK per il Tunnel 1"
  value       = aws_vpn_connection.this.tunnel1_preshared_key
  sensitive   = true # valore nascosto nei log
}

output "tunnel2_preshared_key" {
  description = "PSK per il Tunnel 2"
  value       = aws_vpn_connection.this.tunnel2_preshared_key
  sensitive   = true
}

output "vpn_attachment_id" {
  description = "ID dell'attachment della VPN al TGW"
  value       = aws_vpn_connection.this.transit_gateway_attachment_id
}