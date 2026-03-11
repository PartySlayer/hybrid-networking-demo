variable "vpc_cidr" {
  description = "CIDR block per la Ingress/Inspection VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_cidr" {
  description = "CIDR block per la Public Subnet (ALB, NAT)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "firewall_cidr" {
  description = "CIDR block per la Firewall Subnet (VPC Endpoints del Network Firewall)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "tgw_attach_cidr" {
  description = "CIDR block per la TGW Attachment Subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "az" {
  description = "Availability Zone in cui deployare le risorse"
  type        = string
}

variable "tgw_id" {
  description = "ID del Transit Gateway (iniettato dal main.tf root)"
  type        = string
}

variable "internal_network_cidr" {
  description = "Supernet che riassume tutte le reti interne (AWS + On-Premise)"
  type        = string
  default     = "10.0.0.0/8"
}

variable "public_cidr_2" {
  description = "CIDR block per la seconda Public Subnet (Necessaria per l'ALB)"
  type        = string
  default     = "10.0.11.0/24"
}

variable "az_2" {
  description = "Seconda Availability Zone in cui deployare l'ALB"
  type        = string
}