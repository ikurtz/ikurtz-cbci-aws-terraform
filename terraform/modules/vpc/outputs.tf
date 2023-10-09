
output "vpcid" {
  value = aws_vpc.main.id
}

output "public-subnet-ids" {
  value = aws_subnet.public_sn[*].id
}

output "private-subnet-ids" {
  value = aws_subnet.private_sn[*].id
}

output "vpc-cidr-block" {
  value = aws_vpc.main.cidr_block
}
