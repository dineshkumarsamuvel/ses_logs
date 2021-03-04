output "aws_iam_role_arn" {
  value = aws_iam_role.update_ses_log_in_dynamodb_role.arn
}


output "lambda_function_arn" {
  value = aws_lambda_function.update_ses_log_in_dynamodb_function.arn
}

