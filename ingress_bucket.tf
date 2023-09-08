resource "random_string" "suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "aws_s3_bucket" "ingress" {
  bucket = "mediaconvert-test-ingress-${random_string.suffix.result}"
}

output "ingress_bucket" {
  value = aws_s3_bucket.ingress.bucket
}
