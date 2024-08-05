variable "region" {
  description = "AWS region"
  type        = string
}

variable "lambda_s3_bucket" {
  description = "S3 bucket where the Lambda function code is stored"
  type        = string
}

variable "lambda_s3_key" {
  description = "S3 key for the Lambda function code"
  type        = string
}

variable "sqs_queue_names" {
  description = "List of SQS queue names"
  type        = list(string)
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}
