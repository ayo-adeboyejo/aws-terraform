locals {

  # Common tags applied to all resources
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())

  })


  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"

  # Network naming convention 
  vpc_name = "${local.name_prefix}-vpc"

  # Storage naming convention
  bucket_name = "${local.name_prefix}-${random_id.bucket_suffix.hex}"

  # EC2 naming convention
  ec2_name              = "${local.name_prefix}-ec2"
  security_group_name   = "${local.name_prefix}-admin_sg"
  internet_gateway_name = "${local.name_prefix}-internet_gateway"
  pub_subnet_name       = "${local.name_prefix}-public_subnet"
  public_route_name     = "${local.name_prefix}-public_route"
}


resource "random_id" "bucket_suffix" {
  byte_length = 4

  # Keeps controls when the ID can be regenerated.connection 
  # only regenerate the random suffix if project_name or environment changes"
  keepers = {
    project     = var.project_name
    environment = var.environment

  }

}