resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "quizlab-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.quizlab_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
