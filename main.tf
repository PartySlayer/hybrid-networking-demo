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

# Adesso che abbiamo l'hub centrale e la vpc di ispezione nel mezzo,
# dobbiamo collegare gli "spokes", le VPC dedicate ai workload

# Istanziamo la Workload VPC 1
module "workload_vpc_1" {
  source = "./modules/workload_vpc"

  vpc_name        = "workload-1"
  vpc_cidr        = "10.1.0.0/16"
  app_subnet_cidr = "10.1.1.0/24"
  tgw_subnet_cidr = "10.1.2.0/28" # Basta una /28 per il TGW, anzi meglio per non sprecare IP utili
  az              = var.az
  tgw_id          = aws_ec2_transit_gateway.this.id
}

# Istanziamo la Workload VPC 2
module "workload_vpc_2" {
  source = "./modules/workload_vpc"

  vpc_name        = "workload-2"
  vpc_cidr        = "10.2.0.0/16"
  app_subnet_cidr = "10.2.1.0/24"
  tgw_subnet_cidr = "10.2.2.0/28" # Stessa cosa qui
  az              = var.az
  tgw_id          = aws_ec2_transit_gateway.this.id
}