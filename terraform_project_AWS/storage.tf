# Bucket de S3 para almacenar los datos crudos
resource "aws_s3_bucket" "raw_data_bucket" {
  bucket = "${var.project_name}-raw-data-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

# Base de datos de Timestream
resource "aws_timestreamwrite_database" "main_database" {
  database_name = "${var.project_name}-database"
}

# Tabla de Timestream
resource "aws_timestreamwrite_table" "main_table" {
  database_name = aws_timestreamwrite_database.main_database.database_name
  table_name    = "${var.project_name}-table"
  retention_properties {
    memory_store_retention_period_in_hours = 24
    magnetic_store_retention_period_in_days = 7
  }
}

# Cola de SQS para mensajes de error de la regla de IoT
resource "aws_sqs_queue" "iot_dlq" {
  name = "${var.project_name}-iot-dlq"
}