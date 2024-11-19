
provider "aws" {
  region = "eu-west-1"
}
  
terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
    
  }
  backend "s3" {
    bucket  = "pgr301-2024-terraform-state"
    key     = "./infrastructure/terraform.tfstate"
    region  = "eu-west-1"
  }
}

variable "prefix" {
  type = string
}

resource "aws_sqs_queue" "imggen_que" {
  name = "${var.prefix}-titanv1-imggen-queue"
}

resource "aws_iam_role" "lambda_exec_role" {
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        }
      }
    ]
  })

  name = "${var.prefix}-lambda-exec-role"
}

resource "aws_iam_role_policy" "lambda_imggen_policy" {
  name = "${var.prefix}_LambdaImgGenPolicy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
          ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": "lambda:InvokeFunction",
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        "Resource": "*"
      }
    ]
  })
}

# Attach policy to the role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../sam-app/image_gen/app.py"
  output_path = "${path.module}/lambda-function-payload.zip"
}

resource "aws_lambda_function" "image_generate_lambda" {
  function_name = "${var.prefix}_imggen_lambda_function"
  runtime       = "python3.9"
  handler       = "imggen.lambda_handler"
  role          = aws_iam_role.lambda_exec_role.arn
  filename      = "lambda-function-payload.zip"

  environment {
    variables = {
      LOG_LEVEL  = "DEBUG"
      SQS_QUEUE  = aws_sqs_queue.imggen_que.name
      MODEL_NAME = "titan-v1"
    }
  }
}

resource "aws_lambda_function_url" "imggen_lambda_url" {
  function_name      = aws_lambda_function.image_generate_lambda.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "allow_lambda_url" {
  statement_id          = "AllowLambdaURLInvoke"
  action                = "lambda:InvokeFunctionUrl"
  function_name         = aws_lambda_function.image_generate_lambda.function_name
  principal             = "*"
  function_url_auth_type = aws_lambda_function_url.imggen_lambda_url.authorization_type
}



output "sqs_queue_name" {
  value = aws_sqs_queue.imggen_que.name
}

output "lambda_function_name" {
  value = aws_lambda_function.image_generate_lambda.function_name
}

output "lambda_url" {
  value = aws_lambda_function_url.imggen_lambda_url.function_url
}