resource "aws_s3_bucket" "main_bucket" {
  bucket = local.bucket_name
}


# ------- make the s3 bucket private --------

resource "aws_s3_bucket_public_access_block" "main_bucket_accessblock" {
  bucket = aws_s3_bucket.main_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# ---------- Origin Access Control ------------------
# CloudFront Origin Access Control (OAC) is a security feature that ensures your Amazon S3 
# bucket can only be accessed through CloudFront, not directly from the internet.

resource "aws_cloudfront_origin_access_control" "main_oac" {
  name                              = local.oac_name
  description                       = "Example Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# ------ s3 bucket policy ----------
# ------ This gives permissions to cloud front to access s3 bucket ----------

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.main_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.main_bucket.arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main_s3_distribution.arn
          }
        }
      }
    ]
  })
}


# ------upload objects to s3 bucket --------------
resource "aws_s3_object" "website_files" {
  
  for_each = fileset("${path.module}/www", "**/*")
  bucket = aws_s3_bucket.main_bucket.id
  key    = each.value # name of the object in the bucket
  source = "${path.module}/www/${each.value}" # local path to each object
  etag = filemd5("${path.module}/www/${each.value}")
  content_type = lookup({
    "html" = "text/html",
    "css"  = "text/css",
    "js"   = "application/javascript",
    "json" = "application/json",
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "ico"  = "image/x-icon",
    "txt"  = "text/plain"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}


# -------- create cloufront distribution resource ------------------

resource "aws_cloudfront_distribution" "main_s3_distribution" {

  origin {
    domain_name              = aws_s3_bucket.main_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main_oac.id
    origin_id                = local.s3_origin_id 
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  } 

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.common_tags
}
