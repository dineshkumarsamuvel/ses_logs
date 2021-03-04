//terraform {
//  required_providers {
//    aws = {
//      source  = "hashicorp/aws"
//      version = "~> 3.0"
//    }
//  }
//}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "update_ses_log_in_dynamodb_role" {
  name               = var.lambda_role_name
  assume_role_policy = file("${path.module}/policy/iam_role_policy.json")
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/tmp"
  output_path = "${path.module}/lambda_function/${var.lambda_file_name}.zip"
}


resource "aws_lambda_function" "update_ses_log_in_dynamodb_function" {
  function_name    = var.lambda_function_name
  filename         = "${path.module}/lambda_function/${var.lambda_file_name}.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.update_ses_log_in_dynamodb_role.arn
  runtime          = "python3.8"
  handler          = "update_ses_log_in_dynamodb.lambda_handler"
  timeout          = "60"
  publish          = true

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_name
    }
  }
}

resource "aws_sns_topic" "ses_log_topic" {
  name = "ses_logging"
}

resource "aws_sns_topic_subscription" "sns_subscription_to_lambda" {
  topic_arn = aws_sns_topic.ses_log_topic.arn
  protocol  = var.sns_protocol
  endpoint  = aws_lambda_function.update_ses_log_in_dynamodb_function.arn
}


resource "aws_dynamodb_table" "SESNotifications_table" {
  name         = var.dynamodb_name
  billing_mode = var.dynamodb_billing_mode
  hash_key     = var.dynamodb_primary_partition_sort_key["hash_key"]
  range_key    = var.dynamodb_primary_partition_sort_key["sort_key"]

  dynamic "attribute" {
    for_each = { for index, attribute in var.dynamodb_attributes: index => attribute }
    content {
      name = attribute.value["name"]
      type = attribute.value["type"]
    }
  }

  dynamic "global_secondary_index" {
    for_each = { for index, secondary_index in var.dynamodb_global_secondary_index: index => secondary_index}
    content {
      name               = global_secondary_index.value["name"]
      hash_key           = global_secondary_index.value["hash_key"]
      range_key          = global_secondary_index.value["range_key"]
      projection_type    = global_secondary_index.value["projection_type"]
    }
  }
}

resource "aws_iam_role_policy" "dynamodb_putitem_policy" {
  name        = "dynamodb_putitem_and_cloudwatch_policy"
  role = aws_iam_role.update_ses_log_in_dynamodb_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
       {
          "Effect": "Allow",
          "Action": [
              "DynamoDB:PutItem"
          ],
          "Resource": "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_name}"
      },
      {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.lambda_function_name}:*"
        }
  ]
}
EOF
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_ses_log_in_dynamodb_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ses_log_topic.arn
}

resource "aws_ses_email_identity" "ses_email_identity" {
  email = var.ses_email_identity
}

resource "aws_ses_identity_notification_topic" "configure_ses_notification_for_bounce" {
  topic_arn                = aws_sns_topic.ses_log_topic.arn
  notification_type        = "Bounce"
  identity                 = aws_ses_email_identity.ses_email_identity.arn
  include_original_headers = true
}

resource "aws_ses_identity_notification_topic" "configure_ses_notification_for_complaint" {
  topic_arn                = aws_sns_topic.ses_log_topic.arn
  notification_type        = "Complaint"
  identity                 = aws_ses_email_identity.ses_email_identity.arn
  include_original_headers = true
}

resource "aws_ses_identity_notification_topic" "configure_ses_notification_for_delivery" {
  topic_arn                = aws_sns_topic.ses_log_topic.arn
  notification_type        = "Delivery"
  identity                 = aws_ses_email_identity.ses_email_identity.arn
  include_original_headers = true
}
