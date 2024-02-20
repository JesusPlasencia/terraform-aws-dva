variable "service" {
  description = "Name of Service [Repository]"
  type = string
  default = "tp-common-services"
}

variable "aws_region" {
  description = "AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "eb_rule_name_prefix" {
  description = "The name of the Event Bus Rule"
  type        = string
  default     = "tp-eb-rule"
}

variable "stage" {
  description = "value"
  type        = string
  default     = "dev"
}
