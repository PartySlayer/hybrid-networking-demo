output "vpc_id" {
    description = "CIDR block della rete on premise"
    value = aws_vpc.this.id
}

output "instance_id" {
    value = aws_instance.router.id
}