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

variable "ip_name" {
  type        = string
  description = "The name of the static IP address to reserve"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_address" "static_ip" {
  name   = var.ip_name
  region = var.region
}

output "ip_address" {
  value       = google_compute_address.static_ip.address
  description = "The reserved regional static external IP address"
}
