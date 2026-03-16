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

variable "user_data" {
  description = "Script da eseguire all'avvio dell'istanza"
  type        = string
  default = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y nginx
              echo '<h1>Ciao dall'istanza nel Workload 1 (rispondo dal dietro al firewall!)</h1>' > /usr/share/nginx/html/index.html'
              systemctl start nginx
              systemctl enable nginx
              EOF
}