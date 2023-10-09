/*
vpc
*/
resource "aws_vpc" "main" {
  cidr_block           = var.cidr-block
  enable_dns_support   = var.enable-dns-support
  enable_dns_hostnames = var.dns-host-name
  tags                 = {
    "Name" : "${var.resource-prefix}-vpc",
    "kubernetes.io/cluster/${var.resource-prefix}" : "shared"
  }
}

/*
private subnet
*/
resource "aws_subnet" "private_sn" {
  count             = var.private-subnet-count
  availability_zone = var.availability_zones[count.index]
  cidr_block        = "${var.subnet-cidr-prefix}.${count.index}.0/24"
  vpc_id            = aws_vpc.main.id
  tags              = {
    "Name" : "${var.resource-prefix}_private_sn"
    "kubernetes.io/cluster/${var.resource-prefix}" : "shared"
    "kubernetes.io/role/internal-elb" = 1
  }
}

/*
public subnet
*/
resource "aws_subnet" "public_sn" {
  count                   = var.public-subnet-count
  availability_zone       = var.availability_zones[count.index]
  cidr_block              = "${var.subnet-cidr-prefix}.10${count.index}.0/24"
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags                    = {
    "Name" : "${var.resource-prefix}_public_sn"
    "kubernetes.io/cluster/${var.resource-prefix}" : "shared"
    "kubernetes.io/role/elb" = 1
  }
}

/*
internet gateway
*/
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
  tags   = {
    Name = "${var.resource-prefix}_igw"
  }
}

/*
public route table
*/
resource "aws_route_table" "public_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.resource-prefix}_public_rtb"
  }
}

resource "aws_route_table_association" "public_rtba" {
  count = var.public-subnet-count
  subnet_id      = aws_subnet.public_sn.*.id[count.index]
  route_table_id = aws_route_table.public_rtb.id
}

/*
main route table
*/
resource "aws_route_table" "private_rtb" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-cd-gw.id
  }

  tags = {
    Name = "${var.resource-prefix}_private"
  }
}

resource "aws_route_table_association" "private_rtba" {
  count = var.private-subnet-count
  subnet_id      = aws_subnet.private_sn.*.id[count.index]
  route_table_id = aws_route_table.private_rtb.id
}

resource "aws_eip" "cd_eip" {
  vpc  = true
  tags = {
    "Name" = "${var.resource-prefix}_gwip"
  }

}

/*
nat gateway
*/
resource "aws_nat_gateway" "nat-cd-gw" {
  subnet_id     = aws_subnet.public_sn[0].id
  allocation_id = aws_eip.cd_eip.id
  tags          = {
    "Name" = "${var.resource-prefix}-nat"
  }
}