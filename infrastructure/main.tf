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
    key     = "infrastructure/terraform.tfstate"
    region  = "eu-west-1"
  }
}

variable "prefix" {
  type = string
}


data "aws_s3_bucket" "s3_image_storage" {
  bucket = "pgr301-couch-explorers"
}

# SQS Queue
resource "aws_sqs_queue" "imggen_que" {
  name = "${var.prefix}-titanv1-imggen-queue"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  name = "${var.prefix}-lambda-exec-role"
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.prefix}_sqs_iam_lambda_policy"
  # role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::pgr301-couch-explorers/55/*" # add variable
      },
      {
        Effect = "Allow",
        Action ="lambda:InvokeFunction",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "${aws_sqs_queue.imggen_que.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "lambda_aim_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function THIS IS THE ONE
resource "aws_lambda_function" "image_generator_lambda" {
  function_name = "${var.prefix}_imggen_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_sqs.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256("lambda_sqs.zip")

  environment {
    variables = {
      BUCKET_NAME = data.aws_s3_bucket.s3_image_storage.bucket
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_aim_policy_attachment]
}


resource "aws_lambda_event_source_mapping" "sqs_lambda_trigger"{
  function_name    = aws_lambda_function.image_generator_lambda.arn
  event_source_arn = aws_sqs_que.imggen_que.arn
  batch_size       = 10
}




# Outputs
output "sqs_queue_name" {
  value = aws_sqs_queue.imggen_que.name
}

output "lambda_function_name" {
  value = aws_lambda_function.image_generator_lambda.function_name
}