
resource "aws_s3_bucket" "awesome_things" {
  bucket = "com-kmotrebski-awesome-things"
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_object" "something" {
  bucket = "${aws_s3_bucket.awesome_things.id}"
  key    = "awesome-thing"
  content = "version3"
}
