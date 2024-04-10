resource "aws_instance" "hlab_instance" {
    ami = "ami-0c031a79ffb01a803"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.hlab_public_subnet.id
    vpc_security_group_ids = [aws_security_group.hlab_instance_sg.id]

    associate_public_ip_address = true
    user_data = file("launch.sh")

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

resource "aws_security_group_rule" "public_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
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

output "public_ip" {
    value = aws_instance.hlab_instance.public_ip
    description = "hlab instance ip"
}

output "public_dns" {
    value = aws_instance.hlab_instance.public_dns
    description = "hlab instance dns"
}