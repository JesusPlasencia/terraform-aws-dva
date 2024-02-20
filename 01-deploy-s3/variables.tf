variable "aws_region" {
  description = "AWS region to deploy the resources"
  type = string
  default = "us-east-1"
}

variable "s3_bucket_name" {
  description = "The name of the S3 Bucket"
  type = string
  default = "tp-s3-dev"
}