output "function_arn" {
  value = aws_lambda_function.lambda_function.arn
}

output "iam_role_arn" {
  value = aws_iam_role.lambda_function.arn
}
