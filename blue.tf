data "aws_ami" "blue" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

#create 2 instances and deploy each in the private subnets
resource "aws_instance" "blue" {
  count = var.enable_blue_env ? 2 : 0

  ami                    = data.aws_ami.blue.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.private.ids[count.index % length(data.aws_subnets.private.ids)]
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data = templatefile("${path.module}/init-script.sh", {
    file_content = "blue v1.0 - #${count.index}"
  })
  associate_public_ip_address = true
  tags = {
    Name = "${var.name}-blue-${count.index + 1}"
  }
}

#create a target group called blue
resource "aws_lb_target_group" "blue" {
  name     = "${var.name}-blue-tg-lb"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id

  health_check {
    port     = 80
    protocol = "HTTP"
    timeout  = 3
    interval = 5
  }
}
#attached the instances created in aws_instance.blue into the target group blue
resource "aws_lb_target_group_attachment" "blue" {
  count            = length(aws_instance.blue)
  target_group_arn = aws_lb_target_group.blue.arn
  target_id        = aws_instance.blue[count.index].id
  port             = 80
}
