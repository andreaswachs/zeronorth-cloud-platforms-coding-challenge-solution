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
