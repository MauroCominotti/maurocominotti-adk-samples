provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_bigquery_dataset" "forecasting_dataset" {
  dataset_id                 = var.bq_dataset_id
  project                    = var.bq_project_id # Use the BQ specific project ID
  location                   = var.bq_dataset_location
  description                = "Dataset for ADK Data Science Multi-Agent sample (forecasting sticker sales)."
  delete_contents_on_destroy = true
}

resource "google_compute_instance" "adk_ds_docker_vm" {
  project      = var.gcp_project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable" # Container-Optimized OS is good for Docker
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  // Service account with necessary permissions
  service_account {
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/bigquery",
      "https://www.googleapis.com/auth/aiplatform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/devstorage.read_write"
    ]
  }

  // Metadata startup script to install Docker and run the container
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    set -x

    echo "Starting ADK Data Science Docker VM setup..."

    # Docker is pre-installed on Container-Optimized OS (COS)
    # If using a different OS, you'd need to install Docker here.
    # Example for Debian:
    # sudo apt-get update -y
    # sudo apt-get install -y docker.io
    # sudo systemctl start docker
    # sudo systemctl enable docker

    # Authenticate Docker to GCR (if image is in Artifact Registry/GCR)
    # This is often needed if the VM's service account doesn't have direct pull rights
    # or if you are pulling from a GCR in a *different* project.
    # For COS, gcloud is usually available.
    # gcloud auth configure-docker ${var.gcp_region}-docker.pkg.dev -q || echo "gcloud configure-docker failed, assuming public image or other auth"

    echo "Pulling Docker image: ${var.docker_image_name}"
    docker pull ${var.docker_image_name} || { echo "Failed to pull Docker image"; exit 1; }

    echo "Running Docker container..."
    # Pass environment variables to the Docker container.
    # These will be used by entrypoint.sh to create/update the .env file inside the container.
    docker run -d --restart=always \
      -p 8080:8080 \
      -e GOOGLE_GENAI_USE_VERTEXAI="${var.google_genai_use_vertexai}" \
      -e GOOGLE_API_KEY="${var.google_api_key}" \
      -e GOOGLE_CLOUD_PROJECT="${var.google_cloud_project}" \
      -e GOOGLE_CLOUD_LOCATION="${var.google_cloud_location}" \
      -e NL2SQL_METHOD="${var.nl2sql_method}" \
      -e BQ_PROJECT_ID="${var.bq_project_id}" \
      -e BQ_DATASET_ID="${var.bq_dataset_id}" \
      -e BQML_RAG_CORPUS_NAME_ENV="" \
      -e CODE_INTERPRETER_EXTENSION_NAME_ENV="${var.code_interpreter_extension_name}" \
      -e ROOT_AGENT_MODEL="${var.root_agent_model}" \
      -e ANALYTICS_AGENT_MODEL="${var.analytics_agent_model}" \
      -e BIGQUERY_AGENT_MODEL="${var.bigquery_agent_model}" \
      -e BASELINE_NL2SQL_MODEL="${var.baseline_nl2sql_model}" \
      -e CHASE_NL2SQL_MODEL="${var.chase_nl2sql_model}" \
      -e BQML_AGENT_MODEL="${var.bqml_agent_model}" \
      -e RUN_SETUP_ON_START="true" \
      --name adk_ds_agent_container \
      ${var.docker_image_name}

    echo "ADK Data Science Docker VM setup finished successfully!"
    EOF

  labels = {
    environment = "development"
    project     = "adk-data-science-docker"
  }

  tags = ["http-server", "https-server", "adk-ds-vm"] # For firewall rules

  // Ensure BQ dataset is created before VM starts (though setup scripts handle this too)
  depends_on = [google_bigquery_dataset.forecasting_dataset]
}

resource "google_compute_firewall" "allow_adk_http" {
  name    = "${var.instance_name}-allow-adk-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }
  target_tags = ["adk-ds-vm"]
  source_ranges = ["0.0.0.0/0"] # Allow from anywhere for demo; restrict in production
}
