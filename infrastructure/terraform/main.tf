terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.15.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 1. Enable Required Google Cloud APIs
resource "google_project_service" "enabled_apis" {
  for_each = toset([
    "run.googleapis.com",
    "cloudtasks.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com",
    "secretmanager.googleapis.com",
    "firestore.googleapis.com",
    "firebasedatabase.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# 2. Artifact Registry for Container Images
resource "google_artifact_registry_repository" "docker_repo" {
  provider      = google
  location      = var.region
  repository_id = "png-transfer-docker"
  description   = "Docker repository for PNG Airport Transfer Cloud Run services"
  format        = "DOCKER"
  depends_on    = [google_project_service.enabled_apis]
}

# 3. Dedicated Cloud Run Service Account (Least Privilege)
resource "google_service_account" "cloud_run_sa" {
  account_id   = "png-backend-cloudrun-sa"
  display_name = "PNG Transfer Platform Cloud Run Runtime Identity"
}

# Assign roles
resource "google_project_iam_member" "sa_datastore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "sa_tasks_enqueuer" {
  project = var.project_id
  role    = "roles/cloudtasks.enqueuer"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "sa_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "sa_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# 4. Google Cloud Run Service (Backend)
resource "google_cloud_run_v2_service" "backend_service" {
  name     = "png-transfer-backend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloud_run_sa.email

    scaling {
      min_instance_count = 1 # Keep 1 warm instance for zero cold-start in critical transport operations
      max_instance_count = 10
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = "1000m"
          memory = "1024Mi"
        }
      }

      env {
        name  = "NODE_ENV"
        value = var.environment
      }
      env {
        name  = "PORT"
        value = "8080"
      }
      env {
        name  = "TIMEZONE"
        value = "Pacific/Port_Moresby"
      }
      env {
        name  = "CURRENCY"
        value = "PGK"
      }

      startup_probe {
        http_get {
          path = "/api/v1/health"
          port = 8080
        }
        initial_delay_seconds = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/api/v1/health"
          port = 8080
        }
        period_seconds    = 30
        timeout_seconds   = 5
        failure_threshold = 3
      }
    }
  }

  depends_on = [
    google_project_service.enabled_apis,
    google_project_iam_member.sa_datastore_user
  ]
}

# Allow public invocations for public API routes (authenticated via Firebase Bearer tokens)
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# 5. Cloud Tasks Queue for Delayed Escalations & Flight Polling
resource "google_cloud_tasks_queue" "flight_queue" {
  name     = "png-flight-monitoring-queue"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 10
    max_concurrent_dispatches = 5
  }

  retry_config {
    max_attempts = 5
    min_backoff  = "5s"
    max_backoff  = "300s"
  }
}

resource "google_cloud_tasks_queue" "dispatch_timeout_queue" {
  name     = "png-dispatch-timeout-queue"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 5
  }
}

# 6. Cloud Scheduler for Recurring Operations
resource "google_cloud_scheduler_job" "compliance_cron" {
  name             = "png-compliance-sweep-job"
  description      = "Daily compliance check for driver licenses and firearm permits"
  schedule         = "0 6 * * *" # Every day at 06:00 PNG time
  time_zone        = "Pacific/Port_Moresby"
  attempt_deadline = "300s"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_v2_service.backend_service.uri}/api/v1/compliance/run-check"

    oidc_token {
      service_account_email = google_service_account.cloud_run_sa.email
    }
  }
}

# 7. Pub/Sub Topics for Async Event Distribution
resource "google_pubsub_topic" "emergency_alerts" {
  name = "emergency-sos-alerts"
}

resource "google_pubsub_topic" "operational_events" {
  name = "operational-transfer-events"
}

# 8. Cloud Storage Bucket for Media & Proof of Delivery
resource "google_storage_bucket" "transfer_media_bucket" {
  name          = "${var.project_id}-media"
  location      = "ASIA"
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365 # 1 year retention for proof of delivery and incident media
    }
  }
}

