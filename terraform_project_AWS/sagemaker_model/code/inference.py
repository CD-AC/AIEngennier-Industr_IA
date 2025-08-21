import tensorflow as tf
import numpy as np
import os
import json

# Función que se ejecuta cuando SageMaker carga el modelo
def model_fn(model_dir):
    print("Cargando el modelo...")
    model_path = os.path.join(model_dir, 'best_lstm_model.keras')
    model = tf.keras.models.load_model(model_path)
    print("Modelo cargado exitosamente.")
    return model

# Función para deserializar los datos de entrada
def input_fn(request_body, request_content_type):
    if request_content_type == 'application/json':
        data = json.loads(request_body)
        return np.array(data['instances'])
    else:
        raise ValueError(f"Tipo de contenido no soportado: {request_content_type}")

# Función para hacer la predicción
def predict_fn(input_data, model):
    print("Realizando predicción...")
    input_data = np.expand_dims(input_data, axis=0)
    prediction = model.predict(input_data)
    return prediction

# Función para serializar la salida
def output_fn(prediction, content_type):
    predicted_class = np.argmax(prediction, axis=-1).tolist()
    return json.dumps({'prediction': predicted_class})