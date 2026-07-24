# Observability

## CloudWatch Alarms

cloudwatch-alarms-list.png

12 alarms total: 10 custom alarms covering DLQ message depth, Lambda trigger/worker errors and throttles, RDS CPU and free storage, ALB unhealthy hosts and 5xx count, and ASG CPU — plus 2 system-generated target tracking alarms from the ASG's scaling policy. Several alarms show "Insufficient data," which is expected since those thresholds haven't been exercised under real traffic yet, not a misconfiguration. All alarms route to the same SNS topic (quizlab-alerts).

## CloudWatch Dashboard

cloudwatch-dashboard.png

quizlab-overview brings together ALB request/error counts, healthy vs unhealthy host count, ASG CPU, RDS CPU and free storage, ElastiCache CPU, Lambda trigger vs worker errors/throttles, and SQS queue depth vs DLQ in one view. This is the single screen that would be checked first if something broke — request volume and errors at the edge, then compute and data layer health underneath.

## SNS Subscription

sns-subscription-status.png

Email subscription to quizlab-alerts is confirmed. Alarms only reach someone once this subscription is verified, so this is the last link in the alerting chain actually working end to end.
