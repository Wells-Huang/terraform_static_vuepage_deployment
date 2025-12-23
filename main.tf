# --------------------------------------------------------------------------------------------------
# AWS 提供商設定
# --------------------------------------------------------------------------------------------------
provider "aws" {
  region = "ap-northeast-1." # CloudFront 需要在 ap-northeast-1. 區域建立
}

# --------------------------------------------------------------------------------------------------
# 變數設定
# --------------------------------------------------------------------------------------------------
variable "s3_bucket_name" {
  description = "S3 vue app deployment"
  type        = string
  default     = "my-vue-app-bucket-20251223" # 請更換為一個全域唯一的名稱
}

# --------------------------------------------------------------------------------------------------
# S3 儲存桶：存放靜態網站檔案
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "site_bucket" {
  bucket = var.s3_bucket_name

  # 啟用私有設定，禁止所有公開存取
  tags = {
    Name = "Vue Static Site Bucket"
  }
}

# 封鎖所有 S3 的公開存取
resource "aws_s3_bucket_public_access_block" "site_bucket_pab" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------------------------------------------------------
# CloudFront 權限設定 (OAC - Origin Access Control)
# --------------------------------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "OAC for S3 ${aws_s3_bucket.site_bucket.bucket}"
  description                       = "Origin Access Control for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --------------------------------------------------------------------------------------------------
# CloudFront CDN 分發
# --------------------------------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id                = "S3-${var.s3_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for Vue static site"
  default_root_object = "index.html" # Vue 專案的進入點

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_name}"

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

  # 因為我們跳過 DNS，所以使用 CloudFront 預設的憑證
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "Vue Static Site CDN"
  }
}

# --------------------------------------------------------------------------------------------------
# S3 儲存桶政策：只允許 CloudFront 存取
# --------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site_bucket.arn}/*" # 儲存桶內所有物件
        Condition = {
          StringEquals = {
            # 限制只有我們上面建立的 CloudFront Distribution 可以存取
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

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
