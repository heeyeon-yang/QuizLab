# Compute Layer

This section covers the request path from the edge (CloudFront) down to the application instances (EC2 behind an Auto Scaling Group and an Application Load Balancer). The core design goal here was to keep the compute layer horizontally scalable and self-healing while staying inside AWS Free Tier limits wherever possible.

## Launch Template

launch-template-details.png

The launch template (quizlab-lt) defines the standard configuration every EC2 instance in the Auto Scaling Group launches from: a t3.micro instance type, a fixed AMI, and a single security group that only allows traffic from the ALB on the application port. Using a launch template instead of configuring instances by hand means every instance in the fleet is identical, which matters once the ASG starts replacing unhealthy instances automatically. The instance type choice (t3.micro) is a deliberate Free Tier constraint rather than a performance ceiling — the point of this portfolio project is to demonstrate correct infrastructure design, not to size for production load.

One design decision worth calling out here: since there is no NAT Gateway in this architecture (avoided for cost reasons), these instances are placed in public subnets rather than private ones. Running them in private subnets without a NAT Gateway would have blocked outbound internet access needed for health checks and package updates, which was an early lesson learned while building this out. Traffic into the instance is still tightly controlled through security group chaining rather than network isolation — only the ALB's security group is allowed to reach the instance's security group, so public subnet placement doesn't mean public exposure.

## Auto Scaling Group

asg-instance-management.png

The ASG (quizlab-asg) is configured with a desired capacity of 2 and scaling limits of 2 to 4, meaning the application always runs across at least two instances in two different Availability Zones. This is what makes the ALB health checks below meaningful — if either instance fails a health check, the ASG terminates it and launches a replacement from the launch template without manual intervention. The two-AZ spread also protects against a single AZ outage, which is a basic but important resilience property to have documented for an infrastructure portfolio.

## ALB Target Group Health

alb-target-group-health.png

This is the ALB target group (quizlab-tg) showing both registered instances as healthy. The ALB sits in front of the ASG and is the only thing allowed to reach the EC2 security group directly — this is the second link in the security group chaining pattern used throughout the project (Internet to ALB, ALB to EC2, EC2 to RDS/ElastiCache). Health check status here is the signal the ASG uses to decide whether an instance needs to be replaced, so this screenshot effectively shows the self-healing loop working end to end: ALB checks instance health, reports it back, and the ASG would act on it if a target went unhealthy.

## CloudFront Origins

cloudfront-origins.png

CloudFront is configured with the ALB as a custom origin rather than an S3 bucket, since the application is dynamic (server-rendered responses through the ASG) rather than a static site. This is a distinction worth being explicit about in an interview context — CloudFront in front of S3 is the common pattern people expect, but this project needed CloudFront in front of a load balancer instead, since the origin needs to run application logic per request rather than just serve static files.

## CloudFront General Settings

cloudfront-general.png

The distribution is set to Price Class 100 (shown here as "Use only North America and Europe"), which limits which CloudFront edge locations are used and directly reduces cost. Since this is a portfolio project with no real global user base, there's no benefit to paying for edge locations in every region, so this was a straightforward cost-versus-latency trade-off. Caching is intentionally left disabled at the distribution level, since the origin is a dynamic application rather than static content — enabling default caching here would have risked serving stale application responses.
