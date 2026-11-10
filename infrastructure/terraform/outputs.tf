output "cloud_run_url" {
  description = "The deployed URL of the Cloud Run backend"
  value       = google_cloud_run_v2_service.backend_service.uri
}

output "artifact_registry_repo" {
  description = "Artifact Registry Docker repository URI"
  value       = google_artifact_registry_repository.docker_repo.id
}

output "service_account_email" {
  description = "Dedicated runtime service account email"
  value       = google_service_account.cloud_run_sa.email
}

output "storage_bucket_name" {
  description = "Media storage bucket name"
  value       = google_storage_bucket.transfer_media_bucket.name
}

