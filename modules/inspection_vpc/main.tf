# Definiamo la VPC, abilitando dns support e hostnames

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "inspection-vpc" }
}


# Definiamo 2 subnet pubbliche, in cui vivono ALB e NAT

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_cidr
  availability_zone = var.az
  tags              = { Name = "inspection-public-subnet" }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_cidr_2
  availability_zone = var.az_2
  tags              = { Name = "inspection-public-subnet-2" }
}


# Definiamo la subnet dedicata esclusivamente all'endpoint di Network Firewall

resource "aws_subnet" "firewall" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.firewall_cidr
  availability_zone = var.az
  tags              = { Name = "inspection-firewall-subnet" }
}


# In questa subnet, vengono create le ENI (Elastic Network Interface) utilizzate dal TGW (Transit Gateway)
# per agganciarsi alle VPC di workload

resource "aws_subnet" "tgw_attach" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.tgw_attach_cidr
  availability_zone = var.az
  tags              = { Name = "inspection-tgw-attach-subnet" }
}


# Definiamo l'internet gateway, necessario per il traffico internet bidirezionale

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "inspection-igw" }
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "inspection-nat" }
}

# AWS NETWORK FIREWALL

# Definiamo la policy. Il firewall dispone di due motori di analisi: uno stateless e uno stateful
# inoltriamo tutto al motore stateful (quello stateless, di solito, si usa per droppare pacchetti in caso di DDOS)

# Al fine di dimostrare il networking, è concesso il passaggio a tutto il traffico.

resource "aws_networkfirewall_firewall_policy" "demo" {
  name = "demo-fw-policy"
  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateful_engine_options {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
    stateful_default_actions = ["aws:pass"]
  }
}

# Definiamo la risorsa effettiva del network firewall

resource "aws_networkfirewall_firewall" "fw" {
  name                = "main-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.demo.arn # Agganciamo la policy creata sopra
  vpc_id              = aws_vpc.this.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall.id
  }
}

# Estraiamo dinamicamente l'ID del VPC Endpoint del Firewall
locals {
  fw_vpce_id = element(tolist(aws_networkfirewall_firewall.fw.firewall_status[0].sync_states), 0).attachment[0].endpoint_id
}


# ROUTE TABLES E ASSOCIATIONS
# Facciamo in modo che il traffico, sia in entrata che in uscita, passi sempre per il firewall nel mezzo.


# IGW Edge Route Table (Ingress Routing)
# Devia il traffico ricevuto da internet verso il firewall, entrambe le AZ

resource "aws_route_table" "igw_edge" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block      = aws_subnet.public.cidr_block
    vpc_endpoint_id = local.fw_vpce_id
  }

  route {
    cidr_block      = aws_subnet.public_2.cidr_block
    vpc_endpoint_id = local.fw_vpce_id
  }
  tags = { Name = "inspection-igw-edge-rt" }
}

resource "aws_route_table_association" "igw_edge_assoc" {
  gateway_id     = aws_internet_gateway.igw.id
  route_table_id = aws_route_table.igw_edge.id
}

# Public Route Table
# Gestisce dove va il traffico generato da ALB e NAT


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    cidr_block      = var.internal_network_cidr
    vpc_endpoint_id = local.fw_vpce_id
  }
  tags = { Name = "inspection-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Firewall Route Table
# Gestisce la direzione dei pacchetti DOPO essere stati ispezionati


resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = { Name = "inspection-firewall-rt" }
}

# Rotta agganciata separatamente, per aggiungere logica di depends on tgw attachment
# Di fatto la RT verrebbe creata prima, con l'errore "tgw does not exist"

resource "aws_route" "firewall_to_tgw" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = var.internal_network_cidr
  transit_gateway_id     = var.tgw_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

# Stessa cosa per la vpn site to site

resource "aws_route" "firewall_to_tgw_vpn" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "192.168.10.0/24" # O la variabile che contiene il CIDR della tua VPN
  transit_gateway_id     = var.tgw_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

resource "aws_route_table_association" "firewall_assoc" {
  subnet_id      = aws_subnet.firewall.id
  route_table_id = aws_route_table.firewall.id
}

# TGW Attachment Route Table
# Intercetta i pacchetti provenienti dalle VPC di workload

resource "aws_route_table" "tgw_attach_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = local.fw_vpce_id
  }
  tags = { Name = "inspection-tgw-attach-rt" }
}

resource "aws_route_table_association" "tgw_attach_assoc" {
  subnet_id      = aws_subnet.tgw_attach.id
  route_table_id = aws_route_table.tgw_attach_rt.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [aws_subnet.tgw_attach.id] # Usa la subnet dedicata
  appliance_mode_support = "enable"

  tags = { Name = "inspection-vpc-tgw-attachment" }
}