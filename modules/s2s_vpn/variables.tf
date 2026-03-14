variable "tgw_id" {}
variable "tgw_spoke_rt_id" {}
variable "tgw_inspection_rt_id" {}

variable "on_prem_public_ip" {
  description = "Indirizzo IP pubblico del router on-premises"
  type        = string
}

variable "on_prem_cidr" {
  description = "Classe IP privata della rete on-premises"
  type        = string
}