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
  user_data       = var.user_data
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
  user_data       = ""
}

module "tgw" {
  source = "./modules/tgw"

}

# IP Statico per il nostro Router On-Prem
resource "aws_eip" "vpn_router_ip" {
  domain = "vpc"
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = module.on_prem_simulator_vpc.instance_id
  allocation_id = aws_eip.vpn_router_ip.id
}

module "on_prem_simulator_vpc" {
  source = "./modules/on_prem_vpc"

  vpc_name = "on-premise-network"
  vpc_cidr = "192.168.10.0/24"
  public_subnet_cidr = "192.168.10.0/25"
  az = var.az
  tgw_id = module.tgw.tgw_id
  aws_side_cidr = "10.0.0.0/8"
  vpn_tunnel1_address = module.s2s_vpn.tunnel1_address
  vpn_tunnel1_psk     = module.s2s_vpn.tunnel1_preshared_key
  cgw_public_ip = aws_eip.vpn_router_ip.public_ip

}

module "s2s_vpn" {
  source = "./modules/s2s_vpn"
  on_prem_cidr = "192.168.10.0/24"
  on_prem_public_ip = aws_eip.vpn_router_ip.public_ip
  tgw_id = module.tgw.tgw_id
  tgw_inspection_rt_id = module.tgw.inspection_rt_id
  tgw_spoke_rt_id = module.tgw.spoke_rt_id
}