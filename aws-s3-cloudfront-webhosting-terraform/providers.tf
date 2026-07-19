# --------- terraform configuration ---------- 

terraform {

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# --------- provider configuration ---------- 

# Default provider — used by everything else
provider "aws" {
  region = "ap-south-1"
}

# Aliased provider — used only by resources that explicitly reference it
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}