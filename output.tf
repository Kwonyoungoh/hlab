# 접속을 위한 alb dns
output "alb_dns" {
    value = aws_lb.hlab_alb.dns_name
}