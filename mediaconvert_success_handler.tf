resource "aws_cloudwatch_event_rule" "mediaconvert_success" {
  name        = "mediaconvert-success-${random_string.suffix.result}"
  description = "Trigger for when a MediaConvert job finishes"

  event_pattern = <<-EOF
    {
      "source": [
        "aws.mediaconvert"
      ],
      "detail-type": [
        "MediaConvert Job State Change"
      ],
      "detail": {
        "status": [
          "COMPLETE"
        ]
      }
    }
  EOF 
}

resource "aws_cloudwatch_event_target" "mediaconvert_success_handler" {
  rule      = aws_cloudwatch_event_rule.mediaconvert_success.name
  target_id = "LambdaFunction"
  arn       = module.mediaconvert_success_handler.function_arn
}

resource "aws_lambda_permission" "mediaconvert_success_handler" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = module.mediaconvert_success_handler.function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mediaconvert_success.arn
}

module "mediaconvert_success_handler" {
  source = "./modules/lambda_function"

  function_name = "mediaconvert-success-handler-${random_string.suffix.result}"
  handler       = "lambda_function.lambda_handler"
  iam_policy    = data.aws_iam_policy_document.mediaconvert_success_handler.json
  runtime       = "python3.8"
  source_dir    = "${path.root}/lambda_functions/mediaconvert_success_handler"
  timeout       = 60 # This may need to be adjusted depending on max video length and framerate 

  environment_variables = {
    "JOBS_TABLE"        = aws_dynamodb_table.jobs.name
    "RAW_FRAMES_BUCKET" = aws_s3_bucket.raw_frames.bucket
  }
}

data "aws_iam_policy_document" "mediaconvert_success_handler" {
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
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.raw_frames.arn,
    ]
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      aws_dynamodb_table.jobs.arn
    ]
  }
}
