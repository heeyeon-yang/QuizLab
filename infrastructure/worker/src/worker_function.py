import json
import os
import boto3
from pypdf import PdfReader
from io import BytesIO

s3 = boto3.client("s3")
bedrock = boto3.client("bedrock-runtime", region_name="ap-southeast-2")

MODEL_ID = os.environ["BEDROCK_MODEL_ID"]
RESULTS_BUCKET = os.environ["RESULTS_BUCKET"]


def handler(event, context):
    for record in event["Records"]:
        body = json.loads(record["body"])
        bucket = body["bucket"]
        key = body["key"]

        obj = s3.get_object(Bucket=bucket, Key=key)
        reader = PdfReader(BytesIO(obj["Body"].read()))
        text = "\n".join(page.extract_text() or "" for page in reader.pages)
        text = text[:15000]

        prompt = (
            "Generate 5 multiple-choice practice questions based on this lecture "
            "content. Return valid JSON only.\n\n" + text
        )

        response = bedrock.converse(
            modelId=MODEL_ID,
            messages=[{"role": "user", "content": [{"text": prompt}]}],
        )
        quiz_text = response["output"]["message"]["content"][0]["text"]

        result_key = key.replace(".pdf", "_quiz.json")
        s3.put_object(
            Bucket=RESULTS_BUCKET,
            Key=result_key,
            Body=quiz_text.encode("utf-8"),
            ContentType="application/json",
        )

    return {"statusCode": 200}
