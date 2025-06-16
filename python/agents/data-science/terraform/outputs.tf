output "instance_external_ip" {
  description = "The external IP address of the Compute Engine instance."
  value       = google_compute_instance.adk_ds_docker_vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance."
  value       = "gcloud compute ssh ${var.instance_name} --project=${var.gcp_project_id} --zone=${google_compute_instance.adk_ds_docker_vm.zone}"
}

output "adk_agent_cli_info" {
  description = "To interact with the agent via CLI after SSHing into the VM."
  value       = "The agent should be running inside a Docker container. Check container logs with 'docker logs adk_ds_agent_container'. The ADK CLI runs inside the container."
}

output "adk_web_ui_url" {
  description = "URL to access the ADK Web UI (if the agent is run with 'adk web' and port 8080 is mapped)."
  value       = "http://${google_compute_instance.adk_ds_docker_vm.network_interface[0].access_config[0].nat_ip}:8080"
}
