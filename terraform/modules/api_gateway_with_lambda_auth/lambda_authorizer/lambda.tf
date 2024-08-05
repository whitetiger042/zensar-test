resource "aws_lambda_function" "lambda_authorizer" {
  function_name = var.function_name
  handler       = var.handler
  runtime       = var.runtime
  s3_bucket     = var.s3_bucket
  s3_key        = var.s3_key

  environment {
    variables = {
      # Environment variables here
    }
  }
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "The function handler (e.g., `main.handler`)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., `python3.8`)"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket where the Lambda function code is stored"
  type        = string
}

variable "s3_key" {
  description = "S3 key for the Lambda function code"
  type        = string
}
