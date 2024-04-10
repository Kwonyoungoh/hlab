provider "aws" {
    region = var.aws_region
    access_key = var.iam_access_key
    secret_key = var.iam_secret_key
}

resource "aws_vpc" "hlab_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
      Name = "${var.project_name}-vpc"
    }
}

resource "aws_subnet" "hlab_public_subnet" {
    vpc_id  = aws_vpc.hlab_vpc.id
    cidr_block = var.public_subnet_cidrs[0]
    availability_zone = var.azs[0]

    tags = {
      Name = "${var.project_name}-public-subnet"
    }
}

resource "aws_internet_gateway" "hlab_ig" {
    vpc_id = aws_vpc.hlab_vpc.id

    tags = {
      Name = "${var.project_name}-internet_gateway"
    }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.hlab_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hlab_ig.id
  }

  tags = {
    Name = "${var.project_name}-public-route-table"
  }
}

resource "aws_route_table_association" "public" {
    subnet_id       = aws_subnet.hlab_public_subnet.id
    route_table_id  = aws_route_table.public.id
}

