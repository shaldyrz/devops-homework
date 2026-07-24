terraform {
  backend "gcs" {}
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
  zone    = var.zone
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "interopera-gke-cluster"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc_id
  subnetwork = var.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Private cluster configuration (nodes have only private IPs)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false # Allows public endpoint API access so you can run kubectl from local
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Allow clean deletion via terraform destroy
  deletion_protection = false
}

# Cost-optimized GKE Spot Node Pool (1 node)
resource "google_container_node_pool" "spot_nodes" {
  name       = "spot-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    spot         = true
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      environment = "development"
    }
  }
}

output "cluster_name" {
  value       = google_container_cluster.primary.name
  description = "The name of the GKE Cluster"
}

output "kubernetes_endpoint" {
  value       = google_container_cluster.primary.endpoint
  description = "The GKE Kubernetes API endpoint"
}
