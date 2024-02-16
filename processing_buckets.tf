resource "aws_s3_bucket" "raw_frames" {
  bucket = "mediaconvert-test-raw-frames-${random_string.suffix.result}"
}

resource "aws_s3_bucket" "processed_frames" {
  bucket = "mediaconvert-test-processed-frames-${random_string.suffix.result}"
}
