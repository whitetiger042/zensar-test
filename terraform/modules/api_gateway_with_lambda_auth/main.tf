provider "aws" {
  region = var.region
}

# Lambda function for API Gateway authorization
module "lambda_authorizer" {
  source = "./lambda_authorizer"

  function_name = "my-api-gateway-authorizer"
  handler       = "main.handler"
  runtime       = "python3.8"
  s3_bucket     = var.lambda_s3_bucket
  s3_key        = var.lambda_s3_key
}

# Create an SNS topic
resource "aws_sns_topic" "my_topic" {
  name = "my-sns-topic"
}

# Create SQS queues
resource "aws_sqs_queue" "my_queue" {
  count = length(var.sqs_queue_names)
  name  = var.sqs_queue_names[count.index]
}

# Create SQS queue policies to allow SNS topic to send messages
resource "aws_sqs_queue_policy" "policy" {
  count = length(var.sqs_queue_names)

  queue_url = aws_sqs_queue.my_queue[count.index].url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.my_queue[count.index].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.my_topic.arn
          }
        }
      }
    ]
  })
}

# Subscribe SQS queues to SNS topic
resource "aws_sns_topic_subscription" "subscription" {
  count = length(var.sqs_queue_names)
  
  topic_arn = aws_sns_topic.my_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.my_queue[count.index].arn

  # Enable raw message delivery to avoid SNS formatting
  raw_message_delivery = true
}

# Create an API Gateway REST API
resource "aws_api_gateway_rest_api" "my_api" {
  name        = "my-api-gateway"
  description = "API Gateway with inbuilt  Lambda Authorizer"
}

# Create a resource (e.g., /messages) assuming our request comes at /messages
resource "aws_api_gateway_resource" "messages" {
  parent_id = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part = "messages"
  rest_api_id = aws_api_gateway_rest_api.my_api.id
}

# Create a POST method
resource "aws_api_gateway_method" "post_messages" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = aws_api_gateway_authorizer.my_authorizer.id
}

# Integration with SNS
resource "aws_api_gateway_integration" "sns_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.messages.id
  http_method             = aws_api_gateway_method.post_messages.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:sns:path//${aws_sns_topic.my_topic.name}"
}

# Create a method response
resource "aws_api_gateway_method_response" "response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.post_messages.http_method
  status_code = "200"
}

# Create an integration response
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  resource_id = aws_api_gateway_resource.messages.id
  http_method = aws_api_gateway_method.post_messages.http_method
  status_code = aws_api_gateway_method_response.response.status_code
}

# Create Lambda Authorizer
resource "aws_api_gateway_authorizer" "my_authorizer" {
  name                    = "MyLambdaAuthorizer"
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  authorizer_uri          = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${module.lambda_authorizer.lambda_arn}/invocations"
  authorizer_result_ttl_in_seconds = 300
  type                    = "TOKEN"
  identity_source         = "method.request.header.Authorization"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_authorizer.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${aws_api_gateway_rest_api.my_api.id}/*/*/*"
}
