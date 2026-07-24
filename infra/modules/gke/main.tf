terraform {
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.11.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# GKE Cluster (Zonal, Private, and utilizing GKE DNS Control Plane Endpoint)
resource "google_container_cluster" "primary" {
  name     = "interopera-gke-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc_id
  subnetwork = var.subnet_id

  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Private cluster configuration (nodes have only private IPs, private endpoint enabled)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true # Makes the control plane completely private
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Master Authorized Networks is required to be enabled when private endpoint is enabled
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/20"
      display_name = "gke-subnet-range"
    }
  }

  # Configure DNS-based control plane access (requires google provider >= 6.11.0)
  control_plane_endpoints_config {
    dns_endpoint_config {
      allow_external_traffic = true # Allows resolving and connecting securely via GKE control plane DNS
    }
  }

  # Configure the temporary default node pool to use standard disks to avoid SSD quota limits
  node_config {
    disk_type    = "pd-standard"
    disk_size_gb = 30
  }

  # Allow clean deletion via terraform destroy
  deletion_protection = false
}

# Cost-optimized GKE Spot Node Pool (1 node total in a single zone)
resource "google_container_node_pool" "spot_nodes" {
  name       = "spot-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    spot         = true
    machine_type = "e2-medium"
    
    disk_type    = "pd-standard"
    disk_size_gb = 30

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
