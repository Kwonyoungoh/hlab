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

resource "aws_security_group" "hlab_instance_sg" {
  name = "${var.project_name}-instance-sg"
  vpc_id = aws_vpc.hlab_vpc.id

  tags = {
    Name = "${var.project_name}-instance-sg"
  }
}

resource "aws_security_group_rule" "public_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.hlab_instance_sg.id
}

resource "aws_security_group_rule" "public_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 
  security_group_id = aws_security_group.hlab_instance_sg.id
}