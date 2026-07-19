# ------- create an s3 bucket --------

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
  description                       = "Cloudfront origin access control for s3"
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
  bucket   = aws_s3_bucket.main_bucket.id
  key      = each.value                         # name of the object in the bucket
  source   = "${path.module}/www/${each.value}" # local path to each object
  etag     = filemd5("${path.module}/www/${each.value}")
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


# ── Request SSL certificate ───────────────────────────────────────────────

resource "aws_acm_certificate" "main_cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}


# ----- Create the DNS validation record in Route 53 -----------
# ACM provides a CNAME record that proves you own the domain.
# This resource creates that record automatically in your hosted zone.
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main_route.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}


# ------ Wait for ACM to validate the certificate -----------
# Terraform waits here until ACM confirms the certificate is fully issued.
# Nothing that depends on this certificate will proceed until validation is complete.
resource "aws_acm_certificate_validation" "main_cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.main_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}



# -------- create cloufront distribution resource ------------------

resource "aws_cloudfront_distribution" "main_s3_distribution" {

  aliases = [var.domain_name]

  origin {
    domain_name              = aws_s3_bucket.main_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main_oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
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
    acm_certificate_arn      = aws_acm_certificate_validation.main_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.common_tags
}




# ------ AWS Route 53 ---------------------
resource "aws_route53_zone" "main_route" {
  name = var.route53_name
  tags = local.common_tags
}


# ------ Create AWS Route53 A(Alias) record---------------------
resource "aws_route53_record" "cloudfront_alias" {
  zone_id = aws_route53_zone.main_route.zone_id
  name    = var.domain_name
  type    = "A"


  # -------- Create a binding to the CloudFront distribution resouce ------------
  alias {
    name                   = aws_cloudfront_distribution.main_s3_distribution.domain_name    # CloudFront DNS name
    zone_id                = aws_cloudfront_distribution.main_s3_distribution.hosted_zone_id # CloudFront AWS zone
    evaluate_target_health = false
  }
}
