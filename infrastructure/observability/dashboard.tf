resource "aws_cloudwatch_dashboard" "quizlab" {
  dashboard_name = "quizlab-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB - Requests & 5xx Errors"
          region = "ap-southeast-2"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "app/quizlab-alb/eac00cc246f2394a", { stat = "Sum" }],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "app/quizlab-alb/eac00cc246f2394a", { stat = "Sum" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB - Healthy vs Unhealthy Hosts"
          region = "ap-southeast-2"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", "targetgroup/quizlab-tg/0aca43acd3513d60", "LoadBalancer", "app/quizlab-alb/eac00cc246f2394a", { stat = "Average" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", "targetgroup/quizlab-tg/0aca43acd3513d60", "LoadBalancer", "app/quizlab-alb/eac00cc246f2394a", { stat = "Average" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ASG - CPU Utilization"
          region = "ap-southeast-2"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "quizlab-asg", { stat = "Average" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "RDS - CPU & Free Storage"
          region = "ap-southeast-2"
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "quizlab-db", { stat = "Average" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "quizlab-db", { stat = "Average", yAxis = "right" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ElastiCache - CPU Utilization"
          region = "ap-southeast-2"
          metrics = [
            ["AWS/ElastiCache", "EngineCPUUtilization", "CacheClusterId", "quizlab-cache", { stat = "Average" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Lambda - Trigger vs Worker Errors/Throttles"
          region = "ap-southeast-2"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", "quizlab-quiz-generator", { stat = "Sum", label = "Trigger Errors" }],
            ["AWS/Lambda", "Errors", "FunctionName", "quizlab-quiz-worker", { stat = "Sum", label = "Worker Errors" }],
            ["AWS/Lambda", "Throttles", "FunctionName", "quizlab-quiz-generator", { stat = "Sum", label = "Trigger Throttles" }],
            ["AWS/Lambda", "Throttles", "FunctionName", "quizlab-quiz-worker", { stat = "Sum", label = "Worker Throttles" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "SQS - Queue Depth & DLQ"
          region = "ap-southeast-2"
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "quizlab-quiz-jobs", { stat = "Average", label = "Main Queue" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", "quizlab-quiz-jobs-dlq", { stat = "Average", label = "DLQ" }]
          ]
          period = 300
          view   = "timeSeries"
        }
      }
    ]
  })
}

output "dashboard_url" {
  value = "https://ap-southeast-2.console.aws.amazon.com/cloudwatch/home?region=ap-southeast-2#dashboards:name=quizlab-overview"
}