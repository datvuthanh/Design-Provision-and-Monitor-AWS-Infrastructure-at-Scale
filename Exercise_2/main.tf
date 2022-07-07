provider "aws" {
  access_key = "AKIATA2COYEN4VISTAV2"
  secret_key = "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"
  region     = "us-east-1"
}

data "archive_file" "archive_zip" {
    type = "zip"
    source_file = "greet_lambda.py"
    output_path = var.output_file
}

resource "aws_cloudwatch_log_group" "mylambda_log" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 5
}

resource "aws_iam_role" "QAImy_iam_aws" {
  name = "QAImy_iam_aws"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}



resource "aws_iam_policy" "QAIcloud_logs_policy" {
  name        = "QAIcloud_logs_policy"
  path        = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "QAIcloud_logs_policy" {
  role       = aws_iam_role.QAImy_iam_aws.name
  policy_arn = aws_iam_policy.QAIcloud_logs_policy.arn
}


resource "aws_lambda_function" "my_greeting_lambda" {
  function_name = var.function_name
  filename = data.archive_file.archive_zip.output_path

  source_code_hash = data.archive_file.archive_zip.output_base64sha256

  handler = "greet_lambda.lambda_handler"
  runtime = "python3.9"

  role = aws_iam_role.QAImy_iam_aws.arn

  environment{
      variables = {
          greeting = "Each step is a main component to build big things!"
      }
  }

  depends_on = [aws_iam_role_policy_attachment.QAIcloud_logs_policy,aws_cloudwatch_log_group.mylambda_log]
}