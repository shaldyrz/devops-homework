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

resource "google_compute_network" "vpc" {
  name                    = "interopera-gke-vpc"
  auto_create_subnetworks = false
}

output "vpc_id" {
  value       = google_compute_network.vpc.id
  description = "The ID of the created VPC"
}

output "vpc_name" {
  value       = google_compute_network.vpc.name
  description = "The name of the created VPC"
}
