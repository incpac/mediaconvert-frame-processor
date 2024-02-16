module "frame_processor" {
  source = "./modules/lambda_function"

  function_name = "mediaconvert-frame-processor-${random_string.suffix.result}"
  iam_policy    = data.aws_iam_policy_document.frame_processor.json
  runtime       = "provided.al2"
  architectures = ["arm64"]
  handler       = "bootstrap"
  source_dir    = "${path.root}/lambda_functions/frame_processor/target/lambda/frame-processor"
  timeout       = 120

  environment_variables = {
    "OUTPUT_BUCKET" = aws_s3_bucket.processed_frames.bucket
    "BLUR_MODIFIER" = 8
    "LOG_LEVEL"     = "INFO"
  }
}

data "aws_iam_policy_document" "frame_processor" {
  statement {
    sid = "WriteToCloudWatchLogs"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    sid = "ReadFilesFromRawFramesBucket"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      aws_s3_bucket.raw_frames.arn,
      "${aws_s3_bucket.raw_frames.arn}/*",
    ]
  }

  statement {
    sid = "WriteFilesToProcessedFramesBucket"

    actions = [
      "s3:PutObject"
    ]

    resources = [
      aws_s3_bucket.processed_frames.arn,
      "${aws_s3_bucket.processed_frames.arn}/*"
    ]
  }
}

resource "aws_lambda_permission" "frame_processor_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.frame_processor.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_frames.arn
}

resource "aws_s3_bucket_notification" "frame_processor_trigger" {
  bucket = aws_s3_bucket.raw_frames.id

  lambda_function {
    lambda_function_arn = module.frame_processor.function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.frame_processor_trigger]
}
