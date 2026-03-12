variable "vpc_name" {
  description = "Il nome della VPC (es. workload-1, workload-2)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block dell'intera VPC"
  type        = string
}

variable "app_subnet_cidr" {
  description = "CIDR block per la subnet applicativa (dove girano le EC2)"
  type        = string
}

variable "tgw_subnet_cidr" {
  description = "CIDR block per la subnet dedicata al Transit Gateway Attachment"
  type        = string
}

variable "az" {
  description = "Availability Zone in cui deployare le risorse"
  type        = string
}

variable "tgw_id" {
  description = "ID del Transit Gateway centrale"
  type        = string
}