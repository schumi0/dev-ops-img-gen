import json
import boto3
import os
import base64
import random
# import requests

bedrock_client = boto3.client("bedrock-runtime", region_name="us-east-1")
s3_client = boto3.client("s3")
bucket_name = os.getenv("S3_BUCKET")
CANDIDATE_NR = "55"

def lambda_handler(event, context):
    try:
        body = json.loads(event["body"])
        prompt = body.get("prompt", "empty prompt: generate a lion")
    except (json.JSONDecodeError, KeyError):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid input. Go back try again"})
        }
        
        
    seed = random.randint(0, 2147483647)
    s3_image_path = f"{CANDIDATE_NR}/generated_images/awesome_titan{seed}.png"
    
    native_request = {
        "taskType": "TEXT_IMAGE",
        "textToImageParams": {"text": prompt},
        "imageGenerationConfig": {
            "numberOfImages": 1,
            "quality": "standard",
            "cfgScale": 8.0,
            "height": 1024,
            "width": 1024,
            "seed": seed,
        }
    }
    
    try:
        response = bedrock_client.invoke_model(modelId="amazon.titan-image-generator-v1", body=json.dumps(native_request))
        model_response = json.loads(response["body"].read())
    
    
        # Extract and decode the Base64 image data
        base64_image_data = model_response["images"][0]
        image_data = base64.b64decode(base64_image_data)
        
        # Upload the decoded image data to S3
        s3_client.put_object(Bucket=bucket_name, Key=s3_image_path, Body=image_data)

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Success", "s3_path": f"{bucket_name} -> {s3_image_path}"})
        }
        
        
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error":str(e)})
        }

    if not bucket_name or not prompt:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Please provide both 'bucket_name' and 'prompt' in the request body"})
        }
        
