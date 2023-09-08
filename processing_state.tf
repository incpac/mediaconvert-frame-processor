resource "aws_dynamodb_table" "jobs" {
  name         = "jobs-${random_string.suffix.result}"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "VideoId"

  attribute {
    name = "VideoId"
    type = "S"
  }
}
