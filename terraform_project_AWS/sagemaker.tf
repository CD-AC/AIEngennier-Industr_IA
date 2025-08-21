# Imagen de Docker pre-construida por AWS para inferencia con TensorFlow
data "aws_sagemaker_prebuilt_ecr_image" "tensorflow" {
  repository_name = "tensorflow-inference"
  # Uso de CPU para mantener costos bajos
  image_tag       = "2.12-cpu" 
}

# Definición del modelo de SageMaker
resource "aws_sagemaker_model" "lstm_model" {
  name               = "${var.project_name}-lstm-model"
  execution_role_arn = aws_iam_role.sagemaker_role.arn
  primary_container {
    image          = data.aws_sagemaker_prebuilt_ecr_image.tensorflow.registry_path
    model_data_url = "s3://${var.sagemaker_model_s3_bucket}/${var.sagemaker_model_s3_key}"
    environment = {
      SAGEMAKER_PROGRAM = "inference.py"
    }
  }
}

# Configuración del endpoint
resource "aws_sagemaker_endpoint_configuration" "sagemaker_ep_config" {
  name = "${var.project_name}-ep-config"
  production_variants {
    variant_name           = "AllTraffic"
    model_name             = aws_sagemaker_model.lstm_model.name
    initial_instance_count = 1
    # ml.t2.medium para mantener costos bajos.
    instance_type          = "ml.t2.medium"
  }
}

# Creación del endpoint
resource "aws_sagemaker_endpoint" "sagemaker_ep" {
  name                 = "${var.project_name}-endpoint"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.sagemaker_ep_config.name
}