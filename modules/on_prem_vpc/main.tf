# VPC che simula on-premises e Internet Gateway
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = var.vpc_name }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

# Subnet Pubblica per il Router VPN
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.vpc_name}-public" }
}

# Route Table: Traffico Internet via IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.vpc_name}-public-rt" }
}

resource "aws_route" "on_prem_to_aws" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "10.0.0.0/8"
  network_interface_id   = aws_instance.router.primary_network_interface_id  
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Parte VPN lato AWS

# IL ROUTER ON-PREM (strongSwan)

resource "aws_security_group" "vpn_sg" {
  name   = "${var.vpc_name}-vpn-sg"
  vpc_id = aws_vpc.this.id

  # Porte IPsec (UDP 500, 4500)
  ingress { 
    from_port = 500
    to_port = 500
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    }

  ingress { 
    from_port = 4500
    to_port = 4500
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  
  # Permetti tutto il traffico interno per i test (ICMP/HTTP)
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}


# IAM Role per l'accesso tramite AWS Systems Manager (SSM)
resource "aws_iam_role" "ssm_role" {
  name = "${var.vpc_name}-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.vpc_name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "router" {
  ami           = data.aws_ami.al2023.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.vpn_sg.id]
  
  source_dest_check = false 

  user_data = templatefile("${path.module}/vpn_config.tftpl", {
    cgw_public_ip     = var.cgw_public_ip
    vpn_tunnel1_address = var.vpn_tunnel1_address
    vpn_tunnel1_psk     = var.vpn_tunnel1_psk
    on_prem_cidr      = var.vpc_cidr
    aws_cidr          = var.aws_side_cidr
  })

  tags = { Name = "${var.vpc_name}-router" }
}
