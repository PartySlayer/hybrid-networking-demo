# Customer Gateway, rappresenta il router nel datacenter on-premise
resource "aws_customer_gateway" "on_prem" {
  bgp_asn    = 65000
  ip_address = var.on_prem_public_ip # L'IP pubblico statico dell'ufficio
  type       = "ipsec.1"

  tags = {
    Name = "on-prem-cgw"
  }
}

# VPN Connection agganciata al Transit Gateway
resource "aws_vpn_connection" "this" {
  customer_gateway_id = aws_customer_gateway.on_prem.id
  transit_gateway_id  = var.tgw_id
  type                = aws_customer_gateway.on_prem.type
  static_routes_only  = true # Usiamo rotte statiche per semplicità nella demo

  tags = {
    Name = "tgw-site-to-site-vpn"
  }
}

# Associazione alla Route Table "Spoke" del TGW
# Tutto il traffico in ingresso dalla VPN userà questa tabella (e quindi andrà al Firewall)
resource "aws_ec2_transit_gateway_route_table_association" "vpn_assoc" {
  transit_gateway_attachment_id  = aws_vpn_connection.this.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.tgw_spoke_rt_id
}

# Propagazione/Rotta verso l'Inspection RT
# L'Inspection VPC deve sapere come rimandare indietro il traffico alla VPN
resource "aws_ec2_transit_gateway_route" "vpn_route" {
  destination_cidr_block         = var.on_prem_cidr # es. 192.168.1.0/24
  transit_gateway_attachment_id  = aws_vpn_connection.this.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.tgw_inspection_rt_id
}