variable "aws_region" {
  description = "La región de AWS para desplegar los recursos."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre único para el proyecto."
  type        = string
  default     = "industria-ia-tfm"
}

variable "sagemaker_model_s3_bucket" {
  description = "Nombre del bucket de S3 de model.tar.gz."
  type        = string
  default     = "mi-tfm-model-artifacts-33" 
}

variable "sagemaker_model_s3_key" {
  description = "La clave en el bucket de S3."
  type        = string
  default     = "model.tar.gz"
}

variable "alert_email" {
  description = "Correo electrónico para recibir alertas de mantenimiento."
  type        = string
  default     = "xxx123@gmail.com"
}