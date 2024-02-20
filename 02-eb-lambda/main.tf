terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

//Location Lambda File
data "archive_file" "lambda_zip_file" {
  type        = "zip"
  source_file = "${path.module}/functions/app.js"
  output_path = "${path.module}/lambda.zip"
}

//Create Policy to Publish Logs 
resource "aws_iam_policy" "lambda_logs_group_policy" {
  name        = "lambda-logs-policy"
  description = "IAM policy for Lambda function to log events to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource  = "arn:aws:logs:*:*:*"
    }]
  })
}

//Policy For Assume Role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

//Role For Lambda
resource "aws_iam_role" "lambda_iam_role" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name   = "lambda-logs-inline-policy"
    policy = aws_iam_policy.lambda_logs_group_policy.policy
  }
}

//Creating Lambda
resource "aws_lambda_function" "lambda_event" {
  function_name    = "${var.service}-${var.stage}-MessagingFunction"
  filename         = data.archive_file.lambda_zip_file.output_path
  source_code_hash = data.archive_file.lambda_zip_file.output_base64sha256
  handler          = "app.handler"
  role             = aws_iam_role.lambda_iam_role.arn
  runtime          = "nodejs20.x"

  tracing_config {
    mode = "Active"
  }
}

//Create Log Group
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda_event.function_name}"
}

//Create EventBridge Bus [Producer]
resource "aws_cloudwatch_event_bus" "messenger" {
  name = "chat-messages"
}

//Create EventBridge Rule [Broker]
resource "aws_cloudwatch_event_rule" "eb_rule_messaging_lambda" {
  name        = "${var.service}-${var.stage}-messaging-lambda-rule"
  event_bus_name = aws_cloudwatch_event_bus.messenger.name
  description = "Send events from Event Bus messaging to Lambda"

  event_pattern = <<EOF
{
    "detail-type": ["fluids"],
    "source": ["com.physics"]
}
EOF
}

//Create EventBridge Target [Consumer]
resource "aws_cloudwatch_event_target" "target_lambda_function" {
  rule = aws_cloudwatch_event_rule.eb_rule_messaging_lambda.name
  event_bus_name = aws_cloudwatch_event_bus.messenger.name
  arn = aws_lambda_function.lambda_event.arn
}

//Create Resource Based Policy To Invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_eventbridge" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_event.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.eb_rule_messaging_lambda.arn
}