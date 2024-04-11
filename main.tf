# 1. VPC
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

############################################################

# 2. 웹 서버 인스턴스
# SSM 연결을 위한 IAM 인스턴스 프로파일
data "aws_iam_instance_profile" "ssm" {
  name = "AmazonSSMRoleForInstancesQuickSetup"
}

# 인스턴스 생성
resource "aws_instance" "hlab_instance" {
  ami = "ami-0c031a79ffb01a803"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private[0].id
  user_data = file("launch.sh")
  security_groups = [aws_security_group.hlab_instance_sg.id]
  iam_instance_profile = data.aws_iam_instance_profile.ssm.name

  tags = {
    Name = "${var.project_name}-instance"
  }
}

# 보안그룹 생성 및 소스 보안그룹 추가
resource "aws_security_group" "hlab_instance_sg" {
  name = "${var.project_name}-instance-sg"
  vpc_id = aws_vpc.hlab_vpc.id

  tags = {
    Name = "${var.project_name}-instance-sg"
  }
}

resource "aws_security_group_rule" "instance_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.hlab_instance_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "instance_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 
  security_group_id = aws_security_group.hlab_instance_sg.id
}

############################################################

# 3. ALB
# ALB 생성
resource "aws_lb" "hlab_alb" {
    name = "hlab-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.alb_sg.id]
    subnets = [ for subnet in aws_subnet.public : subnet.id ]

    enable_deletion_protection = false
}

# 80포트 통신을 위한 보안 그룹 생성 및 규칙 작성
resource "aws_security_group" "alb_sg" {
  name = "${var.project_name}-alb-sg"
  vpc_id = aws_vpc.hlab_vpc.id

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group_rule" "alb_http_in" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 
  security_group_id = aws_security_group.alb_sg.id
}

# 타겟 그룹 생성
resource "aws_alb_target_group" "hlab_alb_tg" {
    name = "hlab-alb-tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.hlab_vpc.id
}

# 인스턴스와 타겟 그룹 연결
resource "aws_alb_target_group_attachment" "hlab_instance" {
    target_group_arn = aws_alb_target_group.hlab_alb_tg.arn
    target_id = aws_instance.hlab_instance.id
    port = 80
}

# 리스너 설정
resource "aws_alb_listener" "hlab" {
    load_balancer_arn = aws_lb.hlab_alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "forward"
        target_group_arn = aws_alb_target_group.hlab_alb_tg.arn
    }
}

############################################################

#4. 볼륨

# ebs 볼륨생성
resource "aws_ebs_volume" "hlab_ebs" {
  availability_zone = aws_instance.hlab_instance.availability_zone
  size = 2048

  tags = {
    Name = "${var.project_name}-ebs"
  }
}

# 볼륨 연결
resource "aws_volume_attachment" "hlab_ebs" {
  device_name = "/dev/xvdh"
  volume_id = aws_ebs_volume.hlab_ebs.id
  instance_id = aws_instance.hlab_instance.id
}