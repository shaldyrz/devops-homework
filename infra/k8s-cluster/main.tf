terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "0.6.0"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "default" {
  name           = "interopera-cluster"
  node_image     = "kindest/node:v1.29.2"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      
      # Ingress controller configuration: Map container ports to host ports
      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }
    
    node {
      role = "worker"
    }
  }
}

output "kubeconfig" {
  value     = kind_cluster.default.kubeconfig_path
  sensitive = false
}
