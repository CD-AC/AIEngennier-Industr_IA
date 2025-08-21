resource "aws_iot_topic_rule" "main_rule" {
  name        = "${replace(var.project_name, "-", "_")}_rule"
  description = "Redirige los datos de sensores a S3, Timestream y Lambda"
  enabled     = true
  # Se modifica la consulta para extraer el ID de la máquina del topic
  sql         = "SELECT *, topic(3) as machine_id FROM 'topic/maquinas/+'"
  sql_version = "2016-03-23"

  # Acción para escribir en S3
  s3 {
    bucket_name = aws_s3_bucket.raw_data_bucket.bucket
    key         = "raw-data/${timestamp()}.json"
    role_arn    = aws_iam_role.iot_role.arn
  }

  # Acción para escribir en Timestream
  timestream {
    database_name = aws_timestreamwrite_database.main_database.database_name
    table_name    = aws_timestreamwrite_table.main_table.table_name
    role_arn      = aws_iam_role.iot_role.arn
    dimension {
      name  = "machine_id"
      # Se referencia el alias 'machine_id' creado en la consulta SQL
      value = "machine_id" 
    }
  }

  # Acción para invocar la Lambda que hará la predicción
  lambda {
    function_arn = aws_lambda_function.inference_lambda.arn
  }

  # Acción de error para enviar mensajes fallidos a una cola SQS
  error_action {
    sqs {
      queue_url = aws_sqs_queue.iot_dlq.id
      role_arn  = aws_iam_role.iot_error_role.arn
      # Se añade el argumento requerido 'use_base64'
      use_base64 = false
    }
  }
}

# Permiso para que IoT invoque la función Lambda
resource "aws_lambda_permission" "allow_iot" {
  statement_id  = "AllowExecutionFromIOT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inference_lambda.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = aws_iot_topic_rule.main_rule.arn
}

# Rol de IAM para que la regla de IoT pueda escribir en S3 y Timestream
resource "aws_iam_role" "iot_role" {
  name = "${var.project_name}-iot-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "iot.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "iot_policy" {
  name = "${var.project_name}-iot-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "s3:PutObject"
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.raw_data_bucket.arn}/*"
      },
      {
        Action   = "timestream:WriteRecords"
        Effect   = "Allow"
        Resource = aws_timestreamwrite_table.main_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iot_attach" {
  role       = aws_iam_role.iot_role.name
  policy_arn = aws_iam_policy.iot_policy.arn
}