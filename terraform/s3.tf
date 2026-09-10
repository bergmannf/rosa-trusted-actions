resource "aws_s3_bucket" "app" {
  bucket = var.s3_bucket_name

  tags = { Name = var.s3_bucket_name, Environment = var.environment }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Caps storage growth from the Firehose audit log delivery (see audit_logs.tf).
# No expiration set — audit trail retention is a compliance decision, not an
# infra one. Revisit once a retention period is decided.
resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.app.id

  rule {
    id     = "audit-logs-transition"
    status = "Enabled"

    filter {
      prefix = "audit-logs/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}
