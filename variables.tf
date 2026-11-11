variable "account_id" {
  description = "Harness Account ID"
  type        = string
}

variable "platform_api_key" {
  description = "Harness Service Account Token"
  type        = string
  sensitive   = true
}

variable "org_id" {
  description = "Harness Organization Identifier"
  type        = string
  default     = "FinOps"
}

variable "project_id" {
  description = "Harness Project Identifier"
  type        = string
  default     = "Instance_Scheduler"
}

variable "connector_id" {
  description = "Harness CCM AWS Connector Identifier"
  type        = string
}

variable "connector_name" {
  description = "Harness CCM AWS Connector Name"
  type        = string
}

variable "region" {
  description = "AWS Region of the Instances"
  type        = string
  default     = "us-east-1"
}

variable "dry_run" {
  description = "Create the AutoStopping Rule in Dry Run Mode"
  type        = bool
  default     = true
}
