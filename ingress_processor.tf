data "aws_iam_policy_document" "ingress_processor_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "mediaconvert:CreateJob",
      "mediaconvert:DescribeEndpoints"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [aws_iam_role.mediaconvert.arn]
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]

    resources = [aws_dynamodb_table.jobs.arn]
  }
}

module "ingress_processor" {
  source = "./modules/lambda_function"

  function_name = "ingress-processor-${random_string.suffix.result}"
  handler       = "lambda_function.lambda_handler"
  iam_policy    = data.aws_iam_policy_document.ingress_processor_policy.json
  runtime       = "python3.7"
  source_dir    = "${path.root}/lambda_functions/ingress_processor"

  environment_variables = {
    "FRAMES_BUCKET"     = aws_s3_bucket.raw_frames.bucket
    "JOBS_TABLE"        = aws_dynamodb_table.jobs.name
    "MEDIACONVERT_ROLE" = aws_iam_role.mediaconvert.arn
  }
}

resource "aws_lambda_permission" "ingress_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.ingress_processor.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ingress.arn
}

resource "aws_s3_bucket_notification" "ingress_trigger" {
  bucket = aws_s3_bucket.ingress.id

  lambda_function {
    lambda_function_arn = module.ingress_processor.function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.ingress_trigger]
}
