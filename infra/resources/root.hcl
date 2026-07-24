# Root Terragrunt configuration for all resources

# Configure GCS backend storage dynamically for each resource component
remote_state {
  backend = "gcs"
  config = {
    bucket   = "poc-srz-backend"
    prefix   = "${path_relative_to_include()}/terraform.tfstate"
    project  = "ambient-stone-281407"
    location = "asia-southeast2"
  }
}
