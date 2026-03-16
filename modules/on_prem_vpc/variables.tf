variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_cidr" { type = string }
variable "az" { type = string }
variable "tgw_id" { type = string }
variable "aws_side_cidr" { type = string }

variable "vpn_tunnel1_address" { type = string }
variable "vpn_tunnel1_psk" { type = string }

variable "cgw_public_ip" { type = string }