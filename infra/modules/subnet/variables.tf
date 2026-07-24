variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC network to place the subnet in"
}
