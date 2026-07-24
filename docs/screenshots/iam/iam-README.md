# IAM

## EC2 Role Permissions

iam-ec2-role-permissions.png

quizlab-ec2-role has two managed policies: AmazonSSMManagedInstanceCore and CloudWatchAgentServerPolicy. AmazonS3FullAccess was removed earlier since no application code on the instance needs direct S3 access — uploads and quiz output go through Lambda and the app backend, not the EC2 instance itself.

## Lambda Role Permissions

iam-lambda-role-permissions.png

quizlab-lambda-quiz-worker-role uses a single customer-managed inline policy (quizlab-lambda-quiz-worker-policy) instead of any AWS managed policy. Scoping this as an inline policy tied to exactly one role keeps the permission set specific to what the worker Lambda actually touches, rather than pulling in a broad managed policy with unused permissions.
