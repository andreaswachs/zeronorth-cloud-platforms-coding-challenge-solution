###############################################################################
# IAM policy documents
###############################################################################

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

###############################################################################
# IAM role and policies associations
###############################################################################

resource "aws_iam_role" "lambda_to_bucket_access_role" {
  name               = "lambda_to_bucket_access_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_policy"
  role   = aws_iam_role.lambda_to_bucket_access_role.id
  policy = data.aws_iam_policy_document.lambda_bucket_access.json
}

resource "aws_iam_role_policy" "lambda_logs_policy" {
  name   = "lambda_logs_policy"
  role   = aws_iam_role.lambda_to_bucket_access_role.id
  policy = data.aws_iam_policy_document.lambda_logs_policy.json
}

###############################################################################
# Lambda function setup:
#   - build and zip binary
#   - create lambda function
#   - allow lambda invocation from s3 bucket events
###############################################################################

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

resource "aws_lambda_permission" "bucket_put_lambda_invocation" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}
