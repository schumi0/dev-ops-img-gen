import json

# import requests


def lambda_handler(event, context):

    # try:
    #     ip = requests.get("http://checkip.amazonaws.com/")
    # except requests.RequestException as e:
    #     # Send some context about this error to Lambda Logs
    #     print(e)

    #     raise e
    try:
        body = json.loads(event["body"])
        bucket_name = body.get("bucket_name")
        prompt = body.get("prompt")
    except (json.JSONDecodeError, KeyError):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid input. 'bucket_name' and 'prompt' are required."})
        }

    if not bucket_name or not prompt:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Please provide both 'bucket_name' and 'prompt' in the request body"})
        }
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "generating image",
            # "location": ip.text.replace("\n", "")
        }),
    }
