provider "aws" {
  region = var.aws_region
}

# Modulo Inspection VPC
module "inspection_vpc" {
  source = "./modules/inspection_vpc"

  # Passiamo le variabili richieste dal modulo
  az     = var.az
  az_2   = var.az_2
  tgw_id = module.tgw.tgw_id
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
  tgw_id          = module.tgw.tgw_id
}

# Istanziamo la Workload VPC 2
module "workload_vpc_2" {
  source = "./modules/workload_vpc"

  vpc_name        = "workload-2"
  vpc_cidr        = "10.2.0.0/16"
  app_subnet_cidr = "10.2.1.0/24"
  tgw_subnet_cidr = "10.2.2.0/28" # Stessa cosa qui
  az              = var.az
  tgw_id          = module.tgw.tgw_id
}

module "tgw" {
  source = "./modules/tgw"

}

# Associa Workload 1 alla tabella Spoke

resource "aws_ec2_transit_gateway_route_table_association" "workload_1" {
  transit_gateway_attachment_id  = module.workload_vpc_1.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.spoke_rt_id
}


# Associa Workload 2 alla tabella Spoke

resource "aws_ec2_transit_gateway_route_table_association" "workload_2" {
  transit_gateway_attachment_id  = module.workload_vpc_2.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.spoke_rt_id
}


# Associa Inspection VPC alla sua tabella dedicata

resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = module.inspection_vpc.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.inspection_rt_id
}


# PROPAGAZIONI

# La tabella Inspection deve conoscere le route degli Spoke per poter rispondere
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_learn_workload_1" {
  transit_gateway_attachment_id  = module.workload_vpc_1.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.inspection_rt_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_learn_workload_2" {
  transit_gateway_attachment_id  = module.workload_vpc_2.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.inspection_rt_id
}

# DEFAULT ROUTING 
# Forza il traffico degli spoke verso il Firewall.

# Crea una route di default (0.0.0.0/0) nella tabella spoke che punta all'Inspection VPC
resource "aws_ec2_transit_gateway_route" "spoke_to_inspection" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.inspection_vpc.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.spoke_rt_id
}