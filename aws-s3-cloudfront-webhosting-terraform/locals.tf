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


  bucket_name  = "${local.name_prefix}-${random_id.bucket_suffix.hex}"
  oac_name     = "${local.name_prefix}-oac"
  s3_origin_id = "S3-${aws_s3_bucket.main_bucket.id}"
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