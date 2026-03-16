# Associa Workload 1 alla tabella Spoke

resource "aws_ec2_transit_gateway_route_table_association" "workload_1" {
  transit_gateway_attachment_id  = module.workload_vpc_1.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.spoke_rt_id
}


# Associa Workload 2 alla tabella Spoke

resource "aws_ec2_transit_gateway_route_table_association" "workload_2" {
  transit_gateway_attachment_id  = module.workload_vpc_2.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.spoke_rt_id
}


# Associa Inspection VPC alla sua tabella dedicata

resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = module.inspection_vpc.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.inspection_rt_id
}


# PROPAGAZIONI

# La tabella Inspection deve conoscere le route degli Spoke per poter rispondere
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_learn_workload_1" {
  transit_gateway_attachment_id  = module.workload_vpc_1.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.inspection_rt_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_learn_workload_2" {
  transit_gateway_attachment_id  = module.workload_vpc_2.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.inspection_rt_id
}

# DEFAULT ROUTING 
# Forza il traffico degli spoke verso il Firewall.

# Crea una route di default (0.0.0.0/0) nella tabella spoke che punta all'Inspection VPC
resource "aws_ec2_transit_gateway_route" "spoke_to_inspection" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.inspection_vpc.tgw_attachment_id
  transit_gateway_route_table_id = module.tgw.spoke_rt_id
}

# La tabella Inspection deve sapere come tornare alla VPN
resource "aws_ec2_transit_gateway_route_table_propagation" "inspection_learn_vpn" {
  transit_gateway_attachment_id  = module.s2s_vpn.vpn_attachment_id
  transit_gateway_route_table_id = module.tgw.inspection_rt_id
}