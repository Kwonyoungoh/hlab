# ALB 생성
resource "aws_lb" "hlab_alb" {
    name = "hlab-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [aws_security_group.hlab_instance_sg.id]
    subnets = [ for subnet in aws_subnet.public : subnet.id ]

    enable_deletion_protection = true
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

# 접속을 위한 output 설정
output "alb_dns" {
    value = aws_lb.hlab_alb.dns_name
}