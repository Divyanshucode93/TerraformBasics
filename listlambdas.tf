data "aws_lambda_functions" "list_lambdas" {
  provider = aws
}

output "lambda_functions" {
    value = data.aws_lambda_functions.list_lambdas.function_names
}