variable "aws_region" {
  description = "Regione AWS in cui fare il deploy"
  type        = string
  default     = "eu-west-1"
}

variable "az" {
  description = "Prima Availability Zone per l'Inspection VPC"
  type        = string
  default     = "eu-west-1a" 
}

variable "az_2" {
  description = "Seconda Availability Zone per l'Inspection VPC, per la demo solo per la subnet public"
  type        = string
  default     = "eu-west-1b"
}