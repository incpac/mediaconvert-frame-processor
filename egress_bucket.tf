resource "aws_s3_bucket" "egress" {
  bucket = "mediaconvert-test-egress-${random_string.suffix.result}"
}
