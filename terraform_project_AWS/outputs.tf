output "s3_raw_data_bucket_name" {
  description = "Nombre del bucket S3 para datos crudos."
  value       = aws_s3_bucket.raw_data_bucket.bucket
}

output "sagemaker_endpoint_name" {
  description = "Nombre del endpoint de SageMaker para predicciones."
  value       = aws_sagemaker_endpoint.sagemaker_ep.name
}

output "sns_alerts_topic_arn" {
  description = "ARN del tópico SNS para alertas."
  value       = aws_sns_topic.alerts_topic.arn
}

output "iot_mqtt_topic" {
  description = "Topic de MQTT que publica los datos de los sensores."
  value       = "topic/maquinas/maq-01"
}