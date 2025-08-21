import boto3
import json
import os
import joblib
import numpy as np
from datetime import datetime

# Clientes de AWS
sagemaker_runtime = boto3.client('sagemaker-runtime')
timestream_write = boto3.client('timestream-write')
timestream_query = boto3.client('timestream-query')
sns = boto3.client('sns')

# Variables de entorno que se configuraron en Terraform
SAGEMAKER_ENDPOINT_NAME = os.environ['SAGEMAKER_ENDPOINT_NAME']
TIMESTREAM_DATABASE = os.environ['TIMESTREAM_DATABASE']
TIMESTREAM_TABLE = os.environ['TIMESTREAM_TABLE']
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

# Cargar el scaler 
SCALER = joblib.load('standard_scaler.save')

CLASS_MAP = json.loads(os.environ['CLASS_MAP'])

def lambda_handler(event, context):
    print("Evento recibido:", json.dumps(event))
    
    # Extraer el ID de la máquina del evento de IoT Core
    machine_id = event.get('machine_id', 'unknown_machine')

    try:
        # 1. Consultar los últimos 30 registros de Timestream para esta máquina
        query = f"""
        SELECT time, measure_name, measure_value::double
        FROM "{TIMESTREAM_DATABASE}"."{TIMESTREAM_TABLE}"
        WHERE machine_id = '{machine_id}'
        ORDER BY time DESC
        LIMIT 30
        """
        
        response = timestream_query.query(QueryString=query)
        
        features = [
            event['vibracion'], event['consumo_corriente'], event['presion_neumatica'],
            event['sonido'], event['velocidad_envasado'], event['peso_dosificacion'],
            event['contador_ciclos']
        ]
        
        # 2. Pre-procesar los datos con el scaler
        scaled_features = SCALER.transform([features])

        # 3. Invocar el endpoint de SageMaker
        sagemaker_response = sagemaker_runtime.invoke_endpoint(
            EndpointName=SAGEMAKER_ENDPOINT_NAME,
            ContentType='application/json',
            Body=json.dumps({'instances': scaled_features.tolist()})
        )
        
        result = json.loads(sagemaker_response['Body'].read().decode())
        predicted_class_index = result['prediction'][0]
        predicted_status = CLASS_MAP.get(str(predicted_class_index), 'unknown')
        
        print(f"Máquina: {machine_id}, Estado Predicho: {predicted_status}")

        # 4. Escribir la predicción de vuelta a Timestream
        current_time = str(int(datetime.now().timestamp() * 1000))
        
        record = {
            'Dimensions': [
                {'Name': 'machine_id', 'Value': machine_id},
            ],
            'MeasureName': 'predicted_status',
            'MeasureValue': predicted_status,
            'MeasureValueType': 'VARCHAR',
            'Time': current_time
        }
        
        timestream_write.write_records(
            DatabaseName=TIMESTREAM_DATABASE,
            TableName=TIMESTREAM_TABLE,
            Records=[record]
        )

        # 5. Enviar alerta si es necesario
        if predicted_status in ['pre_falla', 'falla_parada']:
            message = f"¡Alerta de Mantenimiento! Máquina {machine_id} ha entrado en estado: {predicted_status}."
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=message,
                Subject=f"Alerta de Mantenimiento Predictivo"
            )

        return {
            'statusCode': 200,
            'body': json.dumps(f'Predicción exitosa: {predicted_status}')
        }

    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error en el procesamiento: {str(e)}')
        }