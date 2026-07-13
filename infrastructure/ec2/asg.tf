resource "aws_autoscaling_group" "quizlab_asg" {
  name                = "quizlab-asg"
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.quizlab_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.quizlab_tg.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 60

  tag {
    key                 = "Name"
    value               = "quizlab-asg-instance"
    propagate_at_launch = true
  }
}
