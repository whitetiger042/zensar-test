
output "lambda_authorizer_arn" {
  description = "ARN of the Lambda Authorizer"
  value       = module.lambda_authorizer.lambda_arn
}


#Can add more depending on use case 
