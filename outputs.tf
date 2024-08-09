
output "lb_dns_name" {
  value = "http://${aws_lb.app.dns_name}"
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}