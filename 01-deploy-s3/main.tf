terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

resource "random_uuid" "random" {
}

provider "aws" {
  profile = "default"
  region = var.aws_region
}

resource "aws_s3_bucket" "s3_resource" {
  bucket = "${var.s3_bucket_name}-${lower(random_uuid.random.result)}"
  tags = {
    Stage = "dev"
    CreatedBy = "Jesus Plasencia"
  }
}