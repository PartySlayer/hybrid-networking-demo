
# Definiamo il security group per l' ELB (Elastic Load Balancer, in questo caso un APPLICATION LOAD BALANCER)

resource "aws_security_group" "alb_sg" {
  name        = "inspection-alb-sg"
  description = "Consente traffico HTTP/HTTPS da Internet"
  vpc_id      = aws_vpc.this.id # Fa riferimento alla VPC creata nel main.tf

# Regola per il traffico in uscita di default. Per quello in entrata agganciamo singolarmente due regole. 

  egress {
    description = "Traffico in uscita verso le reti interne (Spoke VPCs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.internal_network_cidr]
  }

  tags = { Name = "inspection-alb-sg" }
}

# Consente il traffico HTTP in entrata

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


# Consente il traffico HTTPS in entrata

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


# Definiamo la risorsa vera e propria del Load Balancer

resource "aws_lb" "this" {
  name               = "inspection-alb"
  internal           = false        # Essendo su internet
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id] 

  enable_deletion_protection = false

  tags = { Name = "inspection-alb" }
}


# Definiamo target group e listener
resource "aws_lb_target_group" "workload_tg" {
  name        = "workload-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  
  # ATTENZIONE: Questo è fondamentale!
  # Usiamo "ip" (non "instance") perché i server si trovano in ALTRE VPC collegate tramite Transit Gateway.
  # In questo modo l'ALB indirizzerà il traffico direttamente agli IP privati delle istanze.
  target_type = "ip" 

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.workload_tg.arn
  }
}