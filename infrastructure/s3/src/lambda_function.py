import json
import os
import boto3

sqs = boto3.client("sqs")
QUEUE_URL = os.environ["QUEUE_URL"]


def handler(event, context):
    record = event["Records"][0]["s3"]
    bucket = record["bucket"]["name"]
    key = record["object"]["key"]

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps({"bucket": bucket, "key": key}),
    )

    return {"statusCode": 200, "body": json.dumps({"queued": key})}
