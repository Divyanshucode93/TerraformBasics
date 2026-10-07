resource "aws_s3_bucket" "example" {
  bucket = "div-tf-test-bucket-october26"

  tags = {
    Name        = "My first tf bucket"
    Environment = "Dev"
  }
}
