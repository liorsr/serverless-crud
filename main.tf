provider "aws" {
  region = "us-west-2"
}

# S3 Bucket for Static Website (Public Access)
resource "aws_s3_bucket" "web_bucket" {
  bucket        = "serverless-crud" # Ensure this is globally unique
  force_destroy = true

  tags = {
    Name = "serverless-crud"
  }
}

# S3 Bucket Public Access Block Configuration
resource "aws_s3_bucket_public_access_block" "web_bucket_public_access_block" {
  bucket = aws_s3_bucket.web_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# S3 Bucket Policy for Public Read Access
resource "aws_s3_bucket_policy" "web_bucket_policy" {
  bucket = aws_s3_bucket.web_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.web_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.web_bucket_public_access_block]
}

# Static Website Hosting Configuration (Public Access)
resource "aws_s3_bucket_website_configuration" "web_bucket_website" {
  bucket = aws_s3_bucket.web_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "items" {
  name         = "serverless-crud-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "serverless-crud-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
      },
    ],
  })
}


# Lambda Policy for DynamoDB Acess
resource "aws_iam_policy" "lambda_policy" {
  name        = "serverless-crud-policy"
  description = "Policy for Lambda function to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Scan",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem"

        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.items.arn,
      },
    ],
  })
}

# Associate Policy with Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}


# Lambda Function
resource "aws_lambda_function" "api_function" {
  filename         = "dist/crud_lambda_function.zip"
  function_name    = "serverless-crud-function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "crud_lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("dist/crud_lambda_function.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.items.name
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "serverless-crud-api"
  protocol_type = "HTTP"

  # Provide website API access
  cors_configuration {
    allow_origins = ["http://${aws_s3_bucket.web_bucket.bucket}.s3-website-${aws_s3_bucket.web_bucket.region}.amazonaws.com"]
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["*"]
  }
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id               = aws_apigatewayv2_api.http_api.id
  integration_type     = "AWS_PROXY"
  integration_uri      = aws_lambda_function.api_function.invoke_arn
  integration_method   = "POST"
  timeout_milliseconds = 30000
  # TODO: Fix issue (more in README)
  # payload_format_version = "2.0"  # Set the payload format version here
}

# API Gateway Routes
resource "aws_apigatewayv2_route" "get_item" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "get_items" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "put_item_create" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /items"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "put_item_update" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_item" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE /items/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# Deploy HTML file to S3 with API URL set dynamically
# This must be defined *after* api_stage
data "template_file" "index_html" {
  template = file("dist/index.html.template")

  vars = {
    api_url = aws_apigatewayv2_stage.api_stage.invoke_url
  }
}

resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.web_bucket.id
  key          = "index.html"
  content      = data.template_file.index_html.rendered
  content_type = "text/html"
}

# Output API URL
output "api_invoke_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

# Output website URL
output "website_url" {
  value = "http://${aws_s3_bucket.web_bucket.bucket}.s3-website-${aws_s3_bucket.web_bucket.region}.amazonaws.com"
}
