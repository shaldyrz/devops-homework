variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
}

variable "zone" {
  type        = string
  description = "GCP zone"
  default     = "asia-southeast2-a"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC network"
}

variable "subnet_id" {
  type        = string
  description = "The ID of the Subnet"
}
