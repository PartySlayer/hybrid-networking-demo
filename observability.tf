# S3 bucket per i flow logs
resource "aws_s3_bucket" "flow_logs" {
  bucket = "hybrid-networking-flow-logs-0x0"

  tags = { Name = "hybrid-networking-flow-logs" }
}

# Abilitiamo versioning
resource "aws_s3_bucket_versioning" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Blocchiamo l'accesso pubblico (non dobbiamo hostare nulla)
resource "aws_s3_bucket_public_access_block" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# log del firewall verso s3
resource "aws_flow_log" "fw_to_s3" {
  vpc_id               = module.inspection_vpc.vpc_id
  traffic_type         = "ALL"
  log_destination      = aws_s3_bucket.flow_logs.arn
  log_destination_type = "s3"

  # Deliver logs in Parquet format for better query performance
  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  max_aggregation_interval = 60

  tags = { Name = "hybrid-networking-vpc-flow-log" }
}

## LIFECYCLE POLICIES

# Lifecycle policy per ottimizzare i costi
resource "aws_s3_bucket_lifecycle_configuration" "flow_logs" {
  bucket = aws_s3_bucket.flow_logs.id

  # Sposta a IA (infrequent access) dopo 3 giorni
  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 3
      storage_class = "STANDARD_IA"
    }

    # da IA a Glacier dopo 7 giorni
    transition {
      days          = 7
      storage_class = "GLACIER"
    }

    # Dopo 30 giorni, Glacier Deep Archive
    transition {
      days          = 30
      storage_class = "DEEP_ARCHIVE"
    }

    # Elimina dopo 5 anni (per roba tributaria, dati coperti da gdpr di solito è 5 o 10 anni)
    expiration {
      days = 1825
    }
  }

  # Rimuove gli upload multipart rimasti incompleti
  rule {
    id     = "cleanup-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

