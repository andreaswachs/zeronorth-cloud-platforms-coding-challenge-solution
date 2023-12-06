resource "aws_s3_bucket" "bucket" {
  bucket = "${local.prefix}-bucket"

  # The bucket is highly likely not to be empty, but we want to
  # destroy it when we're done, so we force destruction
  force_destroy = true
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events = ["s3:ObjectCreated:*"]
    filter_suffix = "json"
  }

  depends_on = [aws_lambda_permission.bucket_put_lambda_invocation]
}
