resource "aws_vpc" "paperqa_vpc" {
  cidr_block = "10.0.0.0/16"
  tags       = {
    Name = "paperqa-vpc"
  }
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "paperqa_igw" {
  vpc_id = aws_vpc.paperqa_vpc.id
}

resource "aws_subnet" "paperqa_subnet_a" {
  vpc_id            = aws_vpc.paperqa_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "paperqa_subnet_b" {
  vpc_id            = aws_vpc.paperqa_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}b"
}

resource "aws_route_table" "paperqa_route_table" {
  vpc_id = aws_vpc.paperqa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.paperqa_igw.id
  }

  tags = {
    Name = "paperqa-route-table"
  }
}

resource "aws_route_table_association" "paperqa_subnet_a_association" {
  subnet_id      = aws_subnet.paperqa_subnet_a.id
  route_table_id = aws_route_table.paperqa_route_table.id
}

resource "aws_route_table_association" "paperqa_subnet_b_association" {
  subnet_id      = aws_subnet.paperqa_subnet_b.id
  route_table_id = aws_route_table.paperqa_route_table.id
}
