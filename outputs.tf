# --------------------------------------------------------------------------------------------------
# 輸出 CloudFront 網域，方便我們存取
# --------------------------------------------------------------------------------------------------
output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
  description = "The domain name of the CloudFront distribution"
}

output "s3_bucket_name" {
    value = aws_s3_bucket.site_bucket.id
    description = "The name of the S3 bucket"
}
