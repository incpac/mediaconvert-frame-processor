resource "aws_iam_role" "mediaconvert" {
  name               = "mediaconvert-${random_string.suffix.result}"
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_role.json
}

resource "aws_iam_role_policy" "mediaconvert" {
  name   = aws_iam_role.mediaconvert.name
  role   = aws_iam_role.mediaconvert.id
  policy = data.aws_iam_policy_document.mediaconvert_policy.json
}

data "aws_iam_policy_document" "mediaconvert_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["mediaconvert.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "mediaconvert_policy" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*"
    ]

    resources = ["${aws_s3_bucket.ingress.arn}/*"]
  }

  statement {
    actions = [
      "s3:Put*"
    ]

    resources = ["${aws_s3_bucket.raw_frames.arn}/*"]
  }
}
