resource "aws_lambda_function" "inference_lambda" {
  function_name    = "${var.project_name}-inference-lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SAGEMAKER_ENDPOINT_NAME = aws_sagemaker_endpoint.sagemaker_ep.name
      TIMESTREAM_DATABASE     = aws_timestreamwrite_database.main_database.database_name
      TIMESTREAM_TABLE        = aws_timestreamwrite_table.main_table.table_name
      SNS_TOPIC_ARN           = aws_sns_topic.alerts_topic.arn
      CLASS_MAP               = jsonencode({ "0": "normal", "1": "pre_falla", "2": "falla_parada" })
    }
  }
}