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

# Cloud Router (required for Cloud NAT)
resource "google_compute_router" "router" {
  name    = "interopera-gke-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT (allows GKE private nodes to download Docker images from the internet)
resource "google_compute_router_nat" "nat" {
  name                               = "interopera-gke-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

output "vpc_id" {
  value       = google_compute_network.vpc.id
  description = "The ID of the created VPC"
}

output "vpc_name" {
  value       = google_compute_network.vpc.name
  description = "The name of the created VPC"
}
