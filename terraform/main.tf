# Terraform configuration for Care Connect on GCP
# Client: blue cross home care ltd

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Cloud SQL Database Instance
resource "google_sql_database_instance" "main" {
  name             = "careconnect-${var.client_name}-db"
  database_version = "POSTGRES_15"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"  # Free tier
    
    backup_configuration {
      enabled = true
      start_time = "03:00"
    }
    
    ip_configuration {
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }
}

# Database
resource "google_sql_database" "database" {
  name     = "careconnect"
  instance = google_sql_database_instance.main.name
}

# Database user
resource "google_sql_user" "user" {
  name     = "careconnect"
  instance = google_sql_database_instance.main.name
  password = var.db_password
}

# Frontend Cloud Run Service
resource "google_cloud_run_v2_service" "frontend" {
  name     = "careconnect-${var.client_name}-frontend"
  location = var.region

  template {
    containers {
      image = var.frontend_image
      
      ports {
        container_port = 80
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 5  # Within GCP quota limits
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# Backend Cloud Run Service
resource "google_cloud_run_v2_service" "backend" {
  name     = "careconnect-${var.client_name}-backend"
  location = var.region

  template {
    containers {
      image = var.backend_image
      
      ports {
        container_port = 5000
      }
      
      env {
        name  = "NODE_ENV"
        value = "production"
      }
      
      env {
        name  = "DATABASE_URL"
        value = "postgresql://${google_sql_user.user.name}:${var.db_password}@${google_sql_database_instance.main.private_ip_address}/${google_sql_database.database.name}"
      }
      
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
      
      env {
        name  = "LICENSE_KEY"
        value = var.license_key
      }
      
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }
    
    scaling {
      min_instance_count = 0
      max_instance_count = 5  # Within GCP quota limits
    }
  }

  traffic {
    percent = 100
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

# IAM policy for public access to frontend
resource "google_cloud_run_service_iam_member" "frontend_public" {
  service  = google_cloud_run_v2_service.frontend.name
  location = google_cloud_run_v2_service.frontend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# IAM policy for public access to backend
resource "google_cloud_run_service_iam_member" "backend_public" {
  service  = google_cloud_run_v2_service.backend.name
  location = google_cloud_run_v2_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}