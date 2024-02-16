variable "architectures" {
  description = "CPU architectures to run the Lambda function on"
  default     = ["x86_64"]
  type        = list(string)
}

variable "environment_variables" {
  description = "Dict of environment variables to attach to the Lambda function"
  default     = null
  type        = map(any)
}

variable "function_name" {
  description = "Name of the Lambda function and related resources"
  type        = string
}

variable "handler" {
  description = "Funciton entrypoint"
  type        = string
}

variable "iam_policy" {
  description = "IAM policy to attach to the Lambda Function in JSON"
  type        = string
}

variable "runtime" {
  description = "Lambda Runtime to deploy"
  type        = string
}

variable "source_dir" {
  description = "Directory for the Lambda Functions source code"
  default     = null
  type        = string
}

variable "timeout" {
  description = "Time in seconds before the Lambda function will end with a failed state"
  default     = 3
  type        = number
}
