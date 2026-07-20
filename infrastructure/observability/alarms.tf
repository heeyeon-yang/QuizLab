# ---- ALB / Target Group ----
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "quizlab-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    LoadBalancer = "app/quizlab-alb/eac00cc246f2394a"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "quizlab-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    TargetGroup  = "targetgroup/quizlab-tg/0aca43acd3513d60"
    LoadBalancer = "app/quizlab-alb/eac00cc246f2394a"
  }
}

# ---- ASG ----
resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "quizlab-asg-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    AutoScalingGroupName = "quizlab-asg"
  }
}

# ---- RDS ----
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "quizlab-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    DBInstanceIdentifier = "quizlab-db"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "quizlab-rds-free-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2000000000 # 2GB
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    DBInstanceIdentifier = "quizlab-db"
  }
}

# ---- Lambda ----
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "quizlab-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    FunctionName = "quizlab-quiz-generator"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "quizlab-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    FunctionName = "quizlab-quiz-generator"
  }
}

# ---- SQS DLQ (제일 중요: 실패한 퀴즈 생성 작업 감지) ----
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "quizlab-dlq-has-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    QueueName = "quizlab-quiz-jobs-dlq"
  }
}
resource "aws_cloudwatch_metric_alarm" "lambda_worker_errors" {
  alarm_name          = "quizlab-lambda-worker-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    FunctionName = "quizlab-quiz-worker"
  }
}
resource "aws_cloudwatch_metric_alarm" "lambda_worker_throttles" {
  alarm_name          = "quizlab-lambda-worker-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.alerts.arn]
  dimensions = {
    FunctionName = "quizlab-quiz-worker"
  }
}
