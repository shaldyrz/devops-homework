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
}

resource "google_compute_subnetwork" "subnet" {
  name          = "interopera-gke-subnet"
  ip_cidr_range = "10.0.0.0/20"
  network       = var.vpc_id
  region        = var.region

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.48.0.0/14"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.52.0.0/20"
  }
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "The ID of the created Subnet"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet.name
  description = "The name of the created Subnet"
}
