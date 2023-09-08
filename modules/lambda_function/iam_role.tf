resource "aws_iam_role" "lambda_function" {
  name               = var.function_name
  assume_role_policy = data.aws_iam_policy_document.role.json
}

data "aws_iam_policy_document" "role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "lambda_function" {
  name   = var.function_name
  role   = aws_iam_role.lambda_function.id
  policy = var.iam_policy
}
