resource "aws_lb" "test_lb" {
  name               = "test-lb"
  load_balancer_type = "application"
  idle_timeout = 400
  subnets = var.test_subnet
  security_groups = [var.test_sg]
}

resource "aws_lb_target_group" "test_tg" {
  name = "test-lb-tg-${substr(uuid(), 0, 3)}"
  port = var.tg_port 
  protocol = var.tg_protocol
  vpc_id = var.vpc_id
  lifecycle {
    ignore_changes = [name]
    create_before_destroy = true
     }
  health_check {
    healthy_threshold = var.lb_healthy_threshold  
    unhealthy_threshold = var.lb_unhealthy_threshold 
    timeout =var.lb_timeout 
    interval = var.lb_interval 
  }
}

resource "aws_lb_listener" "test_listener" {
  load_balancer_arn = aws_lb.test_lb.arn
  port = var.listener_port
  protocol = var.listener_protocol
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.test_tg.arn
  }
}