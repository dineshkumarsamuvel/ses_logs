output "aws_iam_role_arn" {
  value = aws_iam_role.dynamodb_ses_logging_role.arn
}


output "lambda_function_arn" {
  value = aws_lambda_function.ses_log_in_dynamodb_function.arn
}

