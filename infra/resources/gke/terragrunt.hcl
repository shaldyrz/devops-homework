# Terragrunt resource configuration for GKE

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../modules/gke"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "mock-vpc-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "subnet" {
  config_path = "../subnet"

  mock_outputs = {
    subnet_id = "mock-subnet-id"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  project_id = "ambient-stone-281407"
  region     = "asia-southeast2"
  zone       = "asia-southeast2-a"
  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_id  = dependency.subnet.outputs.subnet_id
}
