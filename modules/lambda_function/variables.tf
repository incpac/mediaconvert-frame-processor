variable "environment_variables" {
  description = "Dict of environment variables to attach to the Lambda function"
  default     = null
}

variable "function_name" {
  description = "Name of the Lambda function and related resources"
}

variable "handler" {
  description = "Funciton entrypoint"
}

variable "iam_policy" {
  description = "IAM policy to attach to the Lambda Function in JSON"
}

variable "runtime" {
  description = "Lambda Runtime to deploy"
}

variable "source_dir" {
  description = "Directory for the Lambda Functions source code"
}

variable "timeout" {
  description = "Time in seconds before the Lambda function will end with a failed state"
  default     = 3
}
