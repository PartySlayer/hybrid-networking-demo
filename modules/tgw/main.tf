# Creazione del Transit Gateway (Il nostro Hub)

resource "aws_ec2_transit_gateway" "this" {
  description                     = "Il Transit Gateway che funge da HUB per la Hub & Spoke"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  # Abilitiamo il DNS support per permettere la risoluzione dei nomi privati tra le varie VPC agganciate
  dns_support = "enable"

  tags = {
    Name = "main-tgw"
  }
}

# TRANSIT GATEWAY ROUTING 
# Creiamo due tabelle di routing separate:
# - Spoke RT: Manda tutto il traffico in uscita all'Inspection VPC.
# - Inspection RT: Riceve il traffico dagli Spoke e sa dove rispondere.

# Tabella di Routing per gli Spoke (Workload VPCs)
resource "aws_ec2_transit_gateway_route_table" "spoke_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = { Name = "spoke-rt" }
}

# Tabella di Routing per l'Inspection VPC
resource "aws_ec2_transit_gateway_route_table" "inspection_rt" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  tags               = { Name = "inspection-rt" }
}

