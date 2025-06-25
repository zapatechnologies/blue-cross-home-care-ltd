# Terraform variables for blue cross home care ltd

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "bluecrosshomecare-careconnect"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "domain_name" {
  description = "The custom domain name"
  type        = string
  default     = "bluecrosshomecareltd"
}

variable "instance_id" {
  description = "The Care Connect instance ID"
  type        = string
  default     = "74b6fc3f-9c07-4e23-b2a5-f8c0fa7191ee"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ".4ah5l16at0a"
}
