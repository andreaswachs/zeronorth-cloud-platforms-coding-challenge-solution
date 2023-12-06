terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

locals {
  prefix = "cloud-coding-challenge"
  main_file = "main.go"
  binary_name = "main"
  source_path = "lambda/main.go"
  binary_path = "lambda/main"
  archive_path = "lambda/source.zip"
}

provider "aws" {
  region = "eu-north-1"
}
