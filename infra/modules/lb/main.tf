terraform {
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_address" "lb_ip" {
  name   = "interopera-gke-lb-ip"
  region = var.region
}

output "lb_ip_address" {
  value       = google_compute_address.lb_ip.address
  description = "The reserved regional static external IP address"
}
