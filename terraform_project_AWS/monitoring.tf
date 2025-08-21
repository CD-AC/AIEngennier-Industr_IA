# Tópico de SNS para las alertas
resource "aws_sns_topic" "alerts_topic" {
  name = "${var.project_name}-alerts-topic"
}

# Suscripción por email al tópico de SNS
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Alarma para la latencia del endpoint de SageMaker
resource "aws_cloudwatch_metric_alarm" "sagemaker_latency_alarm" {
  alarm_name          = "${var.project_name}-sagemaker-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ModelLatency"
  namespace           = "AWS/SageMaker"
  period              = "300" # 5 minutos
  statistic           = "Average"
  threshold           = "10000" # 10,000 milisegundos = 10 segundos
  alarm_description   = "Alarma cuando la latencia promedio del endpoint de SageMaker es demasiado alta."
  alarm_actions       = [aws_sns_topic.alerts_topic.arn]
  ok_actions          = [aws_sns_topic.alerts_topic.arn]

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.sagemaker_ep.name
    VariantName  = "AllTraffic"
  }
}

# Alarma para errores 5XX en el endpoint de SageMaker
resource "aws_cloudwatch_metric_alarm" "sagemaker_5xx_error_alarm" {
  alarm_name          = "${var.project_name}-sagemaker-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Invocation5XXErrors"
  namespace           = "AWS/SageMaker"
  period              = "300" # 5 minutos
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Alarma cuando el endpoint de SageMaker devuelve errores 5XX."
  alarm_actions       = [aws_sns_topic.alerts_topic.arn]
  ok_actions          = [aws_sns_topic.alerts_topic.arn]

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.sagemaker_ep.name
    VariantName  = "AllTraffic"
  }
}