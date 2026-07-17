output "aws_route53_name_servers" {
  value = aws_route53_zone.main_route.name_servers
}

output "cloudfront_distribution_domain_name" {
  value = aws_cloudfront_distribution.main_s3_distribution.domain_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.main_bucket.id
}


output "route53_zone_id" {
  value = aws_route53_zone.main_route.id
}