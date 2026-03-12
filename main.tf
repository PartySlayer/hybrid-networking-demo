provider "aws" {
  region = var.aws_region
}

# Creazione del Transit Gateway (Il nostro Hub)

resource "aws_ec2_transit_gateway" "this" {
  description                     = "Il Transit Gateway che funge da HUB per la Hub & Spoke"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  
  # Abilitiamo il DNS support per permettere la risoluzione dei nomi privati tra le varie VPC agganciate
  dns_support                     = "enable" 

  tags = {
    Name = "main-tgw"
  }
}

# Modulo Inspection VPC
module "inspection_vpc" {
  source = "./modules/inspection_vpc"

  # Passiamo le variabili richieste dal modulo
  az     = var.az
  az_2   = var.az_2
  tgw_id = aws_ec2_transit_gateway.this.id
}