variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "client_name" {
  description = "Client name for resource naming"
  type        = string
}

variable "frontend_image" {
  description = "Frontend container image"
  type        = string
}

variable "backend_image" {
  description = "Backend container image"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  sensitive   = true
}

variable "license_key" {
  description = "Care Connect license key"
  type        = string
  sensitive   = true
}