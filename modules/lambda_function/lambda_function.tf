resource "random_uuid" "suffix" {
  keepers = {
    for filename in fileset(var.source_dir, "**/*") :
    filename => filemd5("${var.source_dir}/${filename}")
  }
}

data "archive_file" "lambda_function" {
  source_dir  = var.source_dir
  output_path = "${path.module}/lambda-function-${var.function_name}-${random_uuid.suffix.result}.zip"
  type        = "zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_function.arn
  runtime       = var.runtime
  handler       = var.handler
  timeout       = var.timeout
  architectures = var.architectures

  filename = data.archive_file.lambda_function.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_function.output_path)

  dynamic "environment" {
    for_each = var.environment_variables == null ? [] : [1]
    content {
      variables = var.environment_variables
    }
  }
}
