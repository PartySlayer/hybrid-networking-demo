# Generiamo un suffisso casuale per garantire l'univocità del nome del bucket

resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Creiamo il Bucket S3 per lo storage a lungo termine

resource "aws_s3_bucket" "fw_logs" {
  bucket        = "inspection-vpc-fw-logs-${random_string.bucket_suffix.result}"
  force_destroy = true 
  
  tags = { Name = "inspection-fw-logs" }
}

# Blocchiamo l'accesso pubblico al bucket
resource "aws_s3_bucket_public_access_block" "fw_logs_block" {
  bucket                  = aws_s3_bucket.fw_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Log Group per i "Flow Logs" (registra tutti i pacchetti consentiti/ispezionati)

resource "aws_cloudwatch_log_group" "fw_flow_logs" {
  name              = "/aws/network-firewall/flow"
  retention_in_days = 1
}

# Log Group per gli "Alert Logs" (in teoria, registrerebbe i pacchetti bloccati/droppati)

resource "aws_cloudwatch_log_group" "fw_alert_logs" {
  name              = "/aws/network-firewall/alert"
  retention_in_days = 1
}

# Configurazione di Logging agganciata al tuo Firewall

resource "aws_networkfirewall_logging_configuration" "fw_logs" {
  firewall_arn = aws_networkfirewall_firewall.fw.arn

  logging_configuration {
    
    # Configurazione per i log del traffico generale

  log_destination_config {
      log_destination_type = "S3"
      log_type             = "FLOW"
      log_destination = {
        bucketName = aws_s3_bucket.fw_logs.id
        prefix     = "flow-logs/"
      }
    } 

    # Configurazione per i log degli alert (se metto regole di drop in futuro, per una demo anche verso il lato security puro)
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.fw_alert_logs.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}