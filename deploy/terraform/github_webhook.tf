resource "aws_iam_role" "iam_for_github_webhook_lambda" {
  name = "iam_for_github_webhook_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "github_webhook" {
  name = "github_webhook_policy"
  role = aws_iam_role.iam_for_github_webhook_lambda.id

  policy = jsonencode(
    {
      Version  ="2012-10-17",
      Statement = [
        {
          Action  =[
            "logs:CreateLogStream",
            "logs:CreateLogGroup"
          ]
          Resource = [ local.github_webhook_aws_log_group ]
          Effect = "Allow"
        },
        {
          Action = [ "logs:PutLogEvents" ]
          Resource = [ local.github_webhook_aws_log_group ]
          Effect = "Allow"
        }
      ]
    }
  )
}

data "archive_file" "github_webhook" {
  type             = "zip"
  # TODO: referencend source_dir is outside repo
  source_dir      = "${path.module}/../../../github-webhook"
  output_file_mode = "0666"
  excludes = [
    "ruby",
    "extra"
  ]

  output_path      = "${path.module}/files/github_webhook.zip"
}

resource "aws_lambda_function" "github_webhook" {
  function_name = "anonydog_github_webhook"
  role          = aws_iam_role.iam_for_github_webhook_lambda.arn
  timeout       = 30

  handler       = "handler.webhook"
  runtime       = "ruby2.7"

  filename          = data.archive_file.github_webhook.output_path
  source_code_hash  = data.archive_file.github_webhook.output_base64sha256

  layers = [
    aws_lambda_layer_version.github_webhook_gems.arn,
    aws_lambda_layer_version.github_webhook_extra.arn,
  ]

  environment {
    variables = {
      GEM_PATH                = "/opt/2.7.0"
      LD_LIBRARY_PATH         = "/opt/lib"
      GITHUB_API_ACCESS_TOKEN = local.github_api_access_token
      GITHUB_PUBLISH_TOKEN    = local.github_api_access_token
      GITHUB_WEBHOOK_SECRET   = local.github_webhook_secret
      MONGO_DATABASE_URL      = local.mongo_database_url
    }
  }
}

resource "aws_api_gateway_rest_api" "github_webhook" {
  name = "anonydog"
}

resource "aws_api_gateway_resource" "resource" {
  path_part   = "webhook"
  parent_id   = aws_api_gateway_rest_api.github_webhook.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.github_webhook.id
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhook.id
  resource_id   = aws_api_gateway_resource.resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "github_webhook" {
  rest_api_id             = aws_api_gateway_rest_api.github_webhook.id
  resource_id             = aws_api_gateway_resource.resource.id
  http_method             = aws_api_gateway_method.method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.github_webhook.invoke_arn
}

resource "aws_api_gateway_deployment" "github_webhook" {
   depends_on = [
     aws_api_gateway_integration.github_webhook,
   ]

   rest_api_id = aws_api_gateway_rest_api.github_webhook.id
   stage_name  = "default"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.github_webhook.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.github_webhook.execution_arn}/*/*${aws_api_gateway_resource.resource.path}"
}

data "archive_file" "github_webhook_extra_layer" {
  type             = "zip"
  source_dir      = "${path.module}/../../../github-webhook/extra"
  output_file_mode = "0666"

  output_path      = "${path.module}/files/github_webhook_extra_layer.zip"
}

resource "aws_lambda_layer_version" "github_webhook_extra" {
  layer_name  = "extra"
  filename    = data.archive_file.github_webhook_extra_layer.output_path
}

data "archive_file" "github_webhook_gems_layer" {
  type             = "zip"
  source_dir      = "${path.module}/../../../github-webhook/ruby"
  output_file_mode = "0666"

  output_path      = "${path.module}/files/github_webhook_gems_layer.zip"
}

resource "aws_lambda_layer_version" "github_webhook_gems" {
  layer_name  = "gems"
  filename    = data.archive_file.github_webhook_gems_layer.output_path
}

locals {
  # TODO: remove hardcoded account_id
  github_webhook_aws_log_group = "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${aws_lambda_function.github_webhook.function_name}*:*"
  github_webhook_url = "${aws_api_gateway_deployment.github_webhook.invoke_url}/${aws_api_gateway_resource.resource.path_part}"
}