provider "aws" {
  region = var.aws_region
  access_key = var.iam_access_key
  secret_key = var.iam_secret_key
}

# vpc 생성
resource "aws_vpc" "hlab_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 서브넷 생성
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id  = aws_vpc.hlab_vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-public-${var.azs[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.hlab_vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project_name}-private-${var.azs[count.index]}"
  }
}

# 인터넷 게이트웨이 생성 및 vpc 연결
resource "aws_internet_gateway" "hlab_ig" {
    vpc_id = aws_vpc.hlab_vpc.id

    tags = {
      Name = "${var.project_name}-internet_gateway"
    }
}

# nat 게이트웨이 생성 및 연결
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_nat_gateway" "hlab_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "hlab-NAT"
  }
}

# 라우팅테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hlab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hlab_ig.id
  }

  tags = {
    Name = "${var.project_name}-public"
  }
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.hlab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hlab_nat.id
  }

  tags = {
    Name = "${var.project_name}-private-${var.azs[count.index]}"
  }
}

# 라우팅 테이블 연결
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id       = aws_subnet.public[count.index].id
  route_table_id  = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}