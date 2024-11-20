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
# SQS Queue awesome que
resource "aws_sqs_queue" "cara011_img_gen_que" {
  name = "titanv1-img-gen-queue"
}

data "aws_s3_bucket" "s3_image_storage" {
  bucket = "pgr301-couch-explorers"
}

# IAM Role for Lambda
resource "aws_iam_role" "cara011_lambda_role" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda im cool  very cool giga cool suuuuper cool even cooler
resource "aws_iam_policy" "cara011_lambda_policy" {
  name = "${var.prefix}_sqs_iam_lambda_policy"

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
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "${aws_sqs_queue.cara011_img_gen_que.arn}"
      },
      {
        Effect = "Allow"
          Action = [
            "bedrock:InvokeModel"
          ],
          Resource = "*"
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


# Lambda Function THIS IS THE ONE
resource "aws_lambda_function" "cara011_img_gen_lambda_function" {
  function_name = "${var.prefix}_img_gen_lambda_function"
  role          = aws_iam_role.cara011_lambda_role.arn
  handler       = "lambda_sqs.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30
  filename      = data.archive_file.lambda_zip.output_path
  source_code_hash = filebase64sha256("lambda-function-payload.zip")

  environment {
    variables = {
      BUCKET_NAME = data.aws_s3_bucket.s3_image_storage.bucket
    }
  }
  depends_on = [aws_iam_role_policy_attachment.cara011_lambda_aim_policy_attachment]
}


resource "aws_lambda_event_source_mapping" "cara011_sqs_lambda_trigger" {
  function_name    = aws_lambda_function.cara011_img_gen_lambda_function.arn
  event_source_arn = aws_sqs_queue.cara011_img_gen_que.arn
  batch_size       = 10
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/../infrastructure/lambda_sqs.py" # adjust yes
  output_path = "${path.module}/lambda-function-payload.zip"
}


# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "cara011_lambda_aim_policy_attachment" {
  role       = aws_iam_role.cara011_lambda_role.name
  policy_arn = aws_iam_policy.cara011_lambda_policy.arn
  depends_on = [aws_iam_role.cara011_lambda_role]
}

variable "que_name" {
  type = string
}

data "aws_sqs_queue" "sqs_queue" {
  name = var.que_name
}

resource "aws_sns_topic" "que_alarm_topic" {
  name = "que-alarm-topic"
}

resource "aws_sns_topic_subscription" "notif_subscription" {
  topic_arn = aws_sns_topic.que_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_metric_alarm" "last-message-que-alarm" {
  alarm_name          = "${var.prefix}_last_message_que_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 180

  dimensions  = {
    QueueName = var.que_name
  }

  alarm_actions = [aws_sns_topic.que_alarm_topic.arn]
}

# Outputs
output "sqs_que_name" {
  value = aws_sqs_queue.cara011_img_gen_que.name
}

output "lambda_function_name" {
  value = aws_lambda_function.cara011_img_gen_lambda_function.function_name
}

output "notif_email" { 
  value = aws_sns_topic_subscription.notif_subscription
}