terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

locals {
  prefix = "cloud-coding-challenge"
  main_file = "main.go"
  binary_name = "main"
  source_path = "lambda/main.go"
  binary_path = "lambda/main"
  archive_path = "lambda/source.zip"
}

provider "aws" {
  region     = "eu-north-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${local.prefix}-bucket"
}

resource "aws_s3_object" "test_data_file" {
  bucket = aws_s3_bucket.bucket.id
  key = "test.json"
  source = "test.json"
  content_type = "application/json"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events = ["s3:ObjectCreated:*"]
    filter_prefix = "test"
    filter_suffix = ".json"
  }

  depends_on = [aws_lambda_permission.bucket_put_lambda_invocation]
}

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

data "aws_iam_policy_document" "lambda_bucket_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.bucket.arn}",
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "lambda_logs_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

// Attaching the service principal role
resource "aws_iam_role" "lambda_to_bucket_access_role" {
  name               = "lambda_to_bucket_access_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

// attaching the lambda->bucket access policy
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_to_bucket_access_role.id
  policy = data.aws_iam_policy_document.lambda_bucket_access.json
}

// Attaching the lambda logs policy
resource "aws_iam_role_policy" "lambda_logs_policy" {
  name   = "lambda_logs_policy"
  role   = aws_iam_role.lambda_to_bucket_access_role.id
  policy = data.aws_iam_policy_document.lambda_logs_policy.json
}

# We want to compile the Go code into a binary
resource "null_resource" "function_binary" {
  provisioner "local-exec" {
    command = "cd lambda && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 GOFLAGS=-trimpath go build -mod=readonly -ldflags='-s -w' -o ${local.binary_name} ${local.main_file}"
  }
}

data "archive_file" "lambda_zip" {
  depends_on = [null_resource.function_binary]
  type = "zip"
  source_file = local.binary_path
  output_path = local.archive_path
}

resource "aws_lambda_permission" "bucket_put_lambda_invocation" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_lambda_function" "lambda" {
  filename     = data.archive_file.lambda_zip.output_path
  function_name = "${local.prefix}-lambda"
  role          = aws_iam_role.lambda_to_bucket_access_role.arn
  handler       = "main"

  # This runtime is deprecated from 31. of December this year, 
  # but its easier to use this for this challenge
  runtime       = "go1.x" 
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout       = 5
  memory_size   = 128
}


