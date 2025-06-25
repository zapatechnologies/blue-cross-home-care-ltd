# Terraform configuration for Care Connect on Google Cloud Run
# Client: blue cross home care ltd

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Cloud SQL instance
resource "google_sql_database_instance" "main" {
  name             = "${var.project_id}-db"
  database_version = "POSTGRES_15"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    
    backup_configuration {
      enabled = true
      start_time = "03:00"
    }
    
    maintenance_window {
      day  = 7
      hour = 4
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

# Secrets
resource "google_secret_manager_secret" "db_password" {
  secret_id = "db-password"
  
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

# Cloud Run service
resource "google_cloud_run_service" "main" {
  name     = "care-connect"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/care-connect:latest"
        
        ports {
          container_port = 3000
        }
        
        env {
          name  = "NODE_ENV"
          value = "production"
        }
        
        env {
          name  = "INSTANCE_ID"
          value = var.instance_id
        }
        
        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# IAM policy for public access
resource "google_cloud_run_service_iam_member" "public" {
  service  = google_cloud_run_service.main.name
  location = google_cloud_run_service.main.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Custom domain mapping
resource "google_cloud_run_domain_mapping" "main" {
  location = var.region
  name     = var.domain_name

  metadata {
    namespace = var.project_id
  }

  spec {
    route_name = google_cloud_run_service.main.name
  }
}
