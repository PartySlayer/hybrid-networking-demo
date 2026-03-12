resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.vpc_name }
}

# Subnet dove vivranno le nostre istanze applicative

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnet_cidr
  availability_zone = var.az
  tags              = { Name = "${var.vpc_name}-app-subnet" }
}


# Subnet piccolissima dedicata ESCLUSIVAMENTE alle ENI del Transit Gateway

resource "aws_subnet" "tgw_attach" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.tgw_subnet_cidr
  availability_zone = var.az
  tags              = { Name = "${var.vpc_name}-tgw-attach-subnet" }
}


# Creazione dell'Attachment al Transit Gateway

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = var.tgw_id
  vpc_id             = aws_vpc.this.id
  subnet_ids         = [aws_subnet.tgw_attach.id]

  tags = { Name = "${var.vpc_name}-tgw-attachment" }
}


# Route Table per la subnet Applicativa

resource "aws_route_table" "app_rt" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-app-rt" }
}


# ROUTING SPOKE:
# Tutto il traffico che non è destinato alla VPC stessa, viene inviato al TGW.
# Usiamo il depends_on di nuovo per evitare la Race Condition col TGW, come per la inspection VPC

resource "aws_route" "app_to_tgw" {
  route_table_id         = aws_route_table.app_rt.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.tgw_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

resource "aws_route_table_association" "app_assoc" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.app_rt.id
}