variable "gcp_project_id" {
  description = "Google Cloud Project ID for deploying resources."
  type        = string
}

variable "gcp_region" {
  description = "The Google Cloud region to deploy resources in."
  type        = string
  default     = "us-central1"
}

variable "instance_name" {
  description = "Name of the Compute Engine instance."
  type        = string
  default     = "adk-ds-docker-vm"
}

variable "machine_type" {
  description = "Machine type for the Compute Engine instance."
  type        = string
  default     = "e2-medium" # Ensure this has enough memory for Docker and your app
}

variable "disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 50
}

variable "docker_image_name" {
  description = "Full name of the Docker image to deploy (e.g., gcr.io/your-gcp-project-id/adk-ds-agent:latest)."
  type        = string
  # Example: "gcr.io/your-gcp-project-id/adk-ds-agent:latest"
  # Replace with your actual image name in Artifact Registry or Docker Hub
}

# --- Agent Configuration Variables (same as before) ---
variable "google_genai_use_vertexai" {
  type    = number
  default = 1
}

variable "google_api_key" {
  type      = string
  default   = "YOUR_ML_DEV_API_KEY_IF_NOT_USING_VERTEXAI"
  sensitive = true
}

variable "google_cloud_project" { # For Vertex AI services
  type = string
}

variable "google_cloud_location" { # For Vertex AI services
  type    = string
  default = "us-central1"
}

variable "bq_project_id" { # For BigQuery
  type = string
}

variable "bq_dataset_id" {
  type    = string
  default = "forecasting_sticker_sales"
}

variable "bq_dataset_location" {
  type    = string
  default = "US"
}

variable "nl2sql_method" {
  type    = string
  default = "BASELINE"
}

variable "code_interpreter_extension_name" {
  type    = string
  default = ""
}

variable "root_agent_model" {
  type    = string
  default = "gemini-1.5-flash-001"
}

variable "analytics_agent_model" {
  type    = string
  default = "gemini-1.5-flash-001"
}

variable "bigquery_agent_model" {
  type    = string
  default = "gemini-1.5-flash-001"
}

variable "baseline_nl2sql_model" {
  type    = string
  default = "gemini-1.5-flash-001"
}

variable "chase_nl2sql_model" {
  type    = string
  default = "gemini-1.5-flash-001"
}

variable "bqml_agent_model" {
  type    = string
  default = "gemini-1.5-flash-001"
}
