variable "project_id" {
  description = "The Google Cloud / Firebase Project ID"
  type        = string
  default     = "png-airport-transfer-prod"
}

variable "region" {
  description = "The Google Cloud region for services (closest low-latency region to PNG)"
  type        = string
  default     = "asia-southeast1" # Singapore
}

variable "environment" {
  description = "Environment tier (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "container_image" {
  description = "Artifact Registry container image URI for Cloud Run backend"
  type        = string
  default     = "asia-southeast1-docker.pkg.dev/png-airport-transfer-prod/png-transfer-docker/backend:latest"
}

