resource "aws_lb" "quizlab_alb" {
  name               = "quizlab-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = {
    Project = "QuizLab"
  }
}

resource "aws_lb_target_group" "quizlab_tg" {
  name     = "quizlab-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "quizlab_listener" {
  load_balancer_arn = aws_lb.quizlab_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.quizlab_tg.arn
  }
}
