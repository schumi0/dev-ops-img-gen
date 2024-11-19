terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.74.0"
    }
  }
  backend "s3" {
    bucket = "pgr301-2024-terraform-state"
    key    = "lambda-sqs-integration/terraform.tfstate"
    region = "eu-west-1"
  }
}

variable "notification_email" {
  description = "The email address to receive CloudWatch alarm notifications"
  type        = string
}


provider "aws" {
  region = "eu-west-1"
}

# S3 Bucket Data Source
data "aws_s3_bucket" "s3_bucket_storage" {
  bucket = "pgr301-couch-explorers"
}

# SQS Queue
resource "aws_sqs_queue" "image_generation_queue" {
  name = "image_generation_queue"
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_sqs_integration_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda Permissions
resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_sqs_s3_access_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::pgr301-couch-explorers/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "${aws_sqs_queue.image_generation_queue.arn}"
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

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "image_generator" {
  function_name = "ImageGenerationFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_sqs.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  filename         = "lambda_sqs.zip"
  source_code_hash = filebase64sha256("lambda_sqs.zip")

  environment {
    variables = {
      BUCKET_NAME = data.aws_s3_bucket.s3_bucket_storage.bucket
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_policy_attachment]
}

# Link Lambda to SQS with Event Source Mapping
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.image_generation_queue.arn
  function_name    = aws_lambda_function.image_generator.arn
  batch_size       = 10
}

# SNS Topic for CloudWatch Alarm Notifications
resource "aws_sns_topic" "cloudwatch_alarm_topic" {
  name = "sqs-delays-alarm-topic"
}

# SNS Email Subscription for Alarms
resource "aws_sns_topic_subscription" "alarm_email_subscription" {
  topic_arn = aws_sns_topic.cloudwatch_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Alarm for SQS
resource "aws_cloudwatch_metric_alarm" "sqs_oldest_message_alarm" {
  alarm_name          = "SQS-Oldest-Message-Age-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 300

  dimensions = {
    QueueName = aws_sqs_queue.image_generation_queue.name
  }

  alarm_description = "Triggered when the age of the oldest message in the SQS queue exceeds 5 minutes."
  actions_enabled   = true
  alarm_actions     = [aws_sns_topic.cloudwatch_alarm_topic.arn]
}