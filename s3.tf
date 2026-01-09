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
