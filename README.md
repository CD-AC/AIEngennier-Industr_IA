<div align="center">
  <h1>Industr_IA: Predictive Maintenance Platform for Industry 4.0</h1>
</div>

<p>
This project, <strong>Industr_IA</strong>, is a comprehensive predictive maintenance platform designed to anticipate failures in industrial machinery up to three days in advance. Using a Deep Learning (LSTM) model, the platform analyzes real-time sensor data to minimize unplanned production stoppages and optimize maintenance operations.
</p>

<p align="center">
  <img src="xd.gif" alt="Platform Demonstration" width="80%">
</p>

---

## 🚀 Technologies Used
*   **Cloud Provider:** AWS (Amazon Web Services)
*   **Infrastructure as Code:** Terraform
*   **Machine Learning Model:** Python, TensorFlow (Keras), Scikit-learn
*   **Data Ingestion & Processing:** AWS IoT Core, AWS Lambda
*   **Data Storage:** Amazon Timestream, Amazon S3
*   **Model Deployment:** Amazon SageMaker
*   **Monitoring & Alerting:** Amazon CloudWatch, Amazon SNS
*   **Visualization:** Grafana

---

## 🏗️ AWS Infrastructure Architecture

The solution is deployed on a **serverless, event-driven architecture in AWS**, ensuring scalability, flexibility, and cost efficiency.

<p align="center">
  <img src="Img/Infraestructura.png" alt="Infrastructure Architecture" width="70%">
</p>

### Data Workflow
1.  **Plant:** Sensors on the packaging machine send data via an industrial Access Point to an MQTT topic (`topic/maquinas/+`).
2.  **Ingestion:** An **AWS IoT Core** rule subscribes to the MQTT topic. Upon receiving a message, it triggers multiple actions.
3.  **Raw Data Storage:** The raw JSON payload is stored in an **Amazon S3** bucket for backup and future analysis.
4.  **Time-Series Storage:** The data is written to an **Amazon Timestream** database, which is optimized for time-series data and serves as the source for the Grafana dashboards.
5.  **Real-Time Processing:** The IoT rule invokes an **AWS Lambda** function, passing the sensor data as the event payload.
6.  **Prediction:** The Lambda function preprocesses the data using a saved `StandardScaler` and invokes a **Amazon SageMaker Endpoint** to get a failure prediction.
7.  **Model Hosting:** The LSTM model is hosted on a SageMaker Endpoint, which automatically scales to handle prediction requests.
8.  **Alerting:** If the model predicts a high probability of failure (`pre_falla`), the Lambda function publishes a message to an **Amazon SNS** topic, which sends an email notification to the maintenance team.
9.  **Error Handling:** If the IoT Core rule fails to process a message, it is sent to an **Amazon SQS** queue as a Dead-Letter Queue (DLQ) for later inspection.
10. **Visualization:** **Grafana** connects directly to Amazon Timestream to display real-time dashboards of machinery status and model predictions.

---

## 🤖 LSTM Model Architecture

The core of the platform is a stacked **Long Short-Term Memory (LSTM)** recurrent neural network. This architecture is ideal for analyzing time-series data from multiple sensors, allowing it to learn the complex patterns that precede a failure. The model includes regularization layers like Dropout and Batch Normalization to prevent overfitting and improve generalization.

<p align="center">
  <img src="Img/ArquitecturaLTSM.png" alt="LSTM Model Architecture" width="200">
</p>

---

## 📂 Project Structure

```
AIEngennier-Industr_IA/
├── DataSet/
│   └── ds_envasadoras.csv         # Training and validation dataset
├── Img/
│   └── *.png                     # Images and diagrams for documentation
├── terraform_project_AWS/
│   ├── lambda_function/
│   │   ├── lambda_function.py    # Python code for the inference Lambda
│   │   └── standard_scaler.save  # Scaler used for data preprocessing
│   ├── sagemaker_model/
│   │   ├── code/
│   │   │   └── inference.py      # Python script for SageMaker model serving
│   │   └── model.tar.gz          # Compressed model artifacts
│   ├── *.tf                      # Terraform files for AWS infrastructure
│   └── variables.tf              # Input variables for Terraform
├── best_lstm_model.keras         # Trained Keras model
├── Industr_IA_vF.ipynb           # Jupyter Notebook for model training (stored in Git LFS)
└── README.md                     # This file
```

---

## 🛠️ Deployment

The entire AWS infrastructure is managed by Terraform.

### Prerequisites
*   [Terraform CLI](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed.
*   An AWS account with credentials configured for Terraform.
*   The `model.tar.gz` artifact uploaded to an S3 bucket.

### Steps
1.  **Navigate to the Terraform directory:**
    ```bash
    cd terraform_project_AWS
    ```
2.  **Initialize Terraform:**
    This command downloads the necessary AWS provider plugins.
    ```bash
    terraform init
    ```
3.  **Configure Variables:**
    Create a `terraform.tfvars` file or export environment variables to set the required values from `variables.tf`, such as:
    *   `aws_region`: The AWS region to deploy to (e.g., "us-east-1").
    *   `alert_email`: The email address to receive SNS notifications.
    *   `sagemaker_model_s3_bucket`: The name of the S3 bucket containing the model artifact.
    *   `sagemaker_model_s3_key`: The key (path) to the `model.tar.gz` file in the bucket.

4.  **Plan the deployment:**
    This command shows you what resources will be created.
    ```bash
    terraform plan
    ```
5.  **Apply the configuration:**
    This command provisions all the AWS resources. Type `yes` when prompted.
    ```bash
    terraform apply
    ```

---

## 📊 Real-Time Monitoring Dashboards
Dashboards were developed in Grafana to visualize machinery status and model predictions in real time, providing actionable intelligence to plant personnel.

### Normal State
The dashboard shows a low probability of failure and sensor values within normal operating ranges.
<p align="center">
  <img src="Img/Monitorizacion_OK.png" alt="Dashboard in Normal State" width="70%">
</p>

### Failure Prediction
The system detects an anomaly, and the probability of failure increases significantly, warning of a potential impending problem.
<p align="center">
  <img src="Img/Monitorizacion_Falla.png" alt="Dashboard with Failure Prediction" width="70%">
</p>

### Machine Stopped
When the machine is stopped, the sensors do not report data, which is immediately reflected on the dashboard.
<p align="center">
  <img src="Img/Monitorizacion_Parada.png" alt="Dashboard with Machine Stopped" width="70%">
</p>

---

## 🔔 Predictive Alert System
When the model predicts a high probability of failure, the system automatically sends an **email alert** to the maintenance team. The notification includes the sensor values at the time of the alarm to facilitate a quick diagnosis.

<p align="center">
  <img src="Img/AlertaFallaPredictiva.png" alt="Predictive Failure Alert Notification" width="70%">
</p>

---

## 🎯 Model Results

The predictive model was rigorously evaluated, demonstrating high effectiveness in detecting failures:

*   **Overall Accuracy:** 96%
*   **Recall (Sensitivity):** 99%

These results confirm the technical feasibility of the solution and its ability to minimize unexpected downtime.