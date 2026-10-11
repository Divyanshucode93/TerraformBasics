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
  # code_sha256   = data.archive_file.example.output_base64sha256

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
