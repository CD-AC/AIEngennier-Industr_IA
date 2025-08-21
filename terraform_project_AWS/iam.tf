# Rol para la función Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Política con los permisos para la función Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-lambda-policy"
  description = "Política para que Lambda acceda a Timestream, SageMaker, SNS y CloudWatch."
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = "sagemaker:InvokeEndpoint"
        Effect   = "Allow"
        Resource = aws_sagemaker_endpoint.sagemaker_ep.arn
      },
      {
        Action = [
          "timestream:WriteRecords",
          "timestream:Select"
        ]
        Effect   = "Allow"
        Resource = aws_timestreamwrite_table.main_table.arn
      },
      {
        Action   = "sns:Publish"
        Effect   = "Allow"
        Resource = aws_sns_topic.alerts_topic.arn
      }
    ]
  })
}

# Adjuntar la política al rol
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Rol para SageMaker
resource "aws_iam_role" "sagemaker_role" {
  name = "${var.project_name}-sagemaker-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
    }]
  })
}

# Adjuntar política gestionada por AWS a SageMaker para acceso a S3 y ECR
resource "aws_iam_role_policy_attachment" "sagemaker_attach" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Política para que SageMaker acceda al bucket S3 de artefactos
resource "aws_iam_policy" "sagemaker_s3_policy" {
  name        = "${var.project_name}-sagemaker-s3-policy"
  description = "Permite a SageMaker leer los artefactos del modelo desde S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::mi-tfm-model-artifacts-12345/*",
          "arn:aws:s3:::mi-tfm-model-artifacts-12345"
        ]
      }
    ]
  })
}

# Adjuntar la política de S3 al rol de SageMaker
resource "aws_iam_role_policy_attachment" "sagemaker_s3_attach" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = aws_iam_policy.sagemaker_s3_policy.arn
}

# Rol de IAM para la acción de error de IoT
resource "aws_iam_role" "iot_error_role" {
  name = "${var.project_name}-iot-error-role"
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

# Política para permitir la publicación en la cola SQS DLQ
resource "aws_iam_policy" "iot_dlq_policy" {
  name = "${var.project_name}-iot-dlq-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Resource = aws_sqs_queue.iot_dlq.arn
      }
    ]
  })
}

# Adjuntar la política de SQS al rol de error de IoT
resource "aws_iam_role_policy_attachment" "iot_error_attach" {
  role       = aws_iam_role.iot_error_role.name
  policy_arn = aws_iam_policy.iot_dlq_policy.arn
}