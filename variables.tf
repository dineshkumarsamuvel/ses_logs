variable "lambda_role_name" {
  default     = "update_ses_log_in_dynamodb_role"
  description = "IAM role for lambda"
}

variable "lambda_role_policy" {
  default     = "update_ses_log_in_dynamodb_policy"
  description = "IAM role policy"
}

variable "lambda_function_name" {
  default     = "update_ses_log_in_dynamodb_function"
  description = "lambda function name"
}

variable "lambda_file_name" {
  default     = "update_ses_log_in_dynamodb"
  description = "lambda file name"
}

variable "aws_region" {
//  default     = "us-west-2"
  description = "sender aws region"
}

variable "sns_protocol" {
  default     = "lambda"
  description = "protocol to listen to sns topic"
}

variable "dynamodb_name" {
  default     = "SES_logs"
  description = "DynamoDB table name"
}

variable "dynamodb_billing_mode" {
//  default     = "PAY_PER_REQUEST"
  description = "Dynamo db billing mode"
}

variable "dynamodb_primary_partition_sort_key" {
  type        = map(string)
  default     = { hash_key = "SESMessageId", sort_key = "SnsPublishTime" }
  description = "primary partition  key and sort key"
}

variable "dynamodb_attributes" {
  type = list(map(string))
  default = [{
    name = "SESMessageId"
    type = "S"
    }, {
    name = "SnsPublishTime"
    type = "S"
    }, {
    name = "SESMessageType"
    type = "S"
    }, {
    name = "SESComplaintFeedbackType"
    type = "S"
    }
  ]
  description = "dynamodb attributes"
}

variable "dynamodb_global_secondary_index" {
	type = list(map(string))
	default = [{
		name = "SESMessageType-Index"
		hash_key = "SESMessageType"
		range_key = "SnsPublishTime"
		projection_type = "KEYS_ONLY"
		}, {
		name = "SESMessageComplaintType-Index"
		hash_key = "SESComplaintFeedbackType"
		range_key = "SnsPublishTime"
		projection_type = "KEYS_ONLY"
		}
	]
}

variable "ses_notification_types" {
  type = list(string)
  default = ["Bounce", "Complaint", "Delivery"]
}

variable "ses_email_identity" {
  type = list
//  email = ""
}