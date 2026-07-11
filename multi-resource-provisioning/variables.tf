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

variable "availability_zone" {
  description = "AWS availability zone for the resources"
  type        = list(string)
  default     = ["ap-south-1", "ap-south-2"]

}

variable "vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) # check if the CIDR  supplied is valid, if not, show the error message
    error_message = "VPC CIDR must be a valid IPV4 CIDR block"
  }

}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0)) # check if the CIDR  supplied is valid, if not, show the error message
    error_message = "Public subnet CIDR must be a valid IPV4 CIDR block"
  }
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1

}

variable "enable_monitoring" {
  description = "Enables monitoring"
  type        = bool
  default     = true

}


variable "enable_public_ip" {
  description = "Enables public IP address"
  type        = bool
  default     = true
}