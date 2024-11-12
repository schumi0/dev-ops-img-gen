from aws_lambda_powertools.event_handler import APIGatewayRestResolver
from aws_lambda_powertools.utilities.typing import LambdaContext
from aws_lambda_powertools.logging import correlation_paths
from aws_lambda_powertools import Logger
from aws_lambda_powertools import Tracer
from aws_lambda_powertools import Metrics
from aws_lambda_powertools.metrics import MetricUnit

import sys
import json
import boto3

from generate_image import generate_image

app = APIGatewayRestResolver()
tracer = Tracer()
logger = Logger()
metrics = Metrics(namespace="Powertools")

@app.post("/generate_image{prompt}")
@tracer.capture_method
def app_generate_image(prompt):
    payload = {"prompt": prompt}
    
    try:
        response = request.post("URL", json=payload)
        
        if response.status_code == 200:
            print("Success")
            response_data = response.json()
        else:
            print("failed")
    
    except Exception as e:
        print("fail?")