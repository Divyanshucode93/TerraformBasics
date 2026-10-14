resource "aws_s3_bucket" "tf_s3_bucket_level1" {
  bucket = "div-tf-test-bucket-october26"

  tags = {
    Name        = "My first tf bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "tf_s3_bucket_versioning_level1" {
  bucket = aws_s3_bucket.tf_s3_bucket_level1.id
  versioning_configuration {
    status = "Enabled"
  }
}


# IAM role for Lambda execution
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

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# 1. Attach basic execution policy so Lambda can write logs to CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Package the Lambda function code
data "archive_file" "package_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda/function.zip"
}

# Lambda function
resource "aws_lambda_function" "tf_lambda_function_level1" {
  filename      = data.archive_file.package_lambda.output_path
  function_name = "tf_lambda_function_october26"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  # code_sha256   = data.archive_file.package_lambda.output_base64sha256

  runtime = "python3.12"

  # environment {
  #   variables = {
  #     ENVIRONMENT = "production"
  #     LOG_LEVEL   = "info"
  #   }
  # }

  tags = {
    Environment = "production"
    Application = "example"
  }
}

# 2. Allow S3 to trigger your Lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tf_lambda_function_level1.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.tf_s3_bucket_level1.arn
}

# 3. Configure S3 event trigger
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.tf_s3_bucket_level1.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.tf_lambda_function_level1.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
