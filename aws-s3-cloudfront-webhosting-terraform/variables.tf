variable "project_name" {
  description = "Name of Project"
  type        = string
}

variable "environment" {
  description = " Environment name (dev, staging, production)"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging or production"
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "route53_name" {
  description = "value"
  type        = string
}

variable "domain_name" {
  description = "value"
  type        = string
}