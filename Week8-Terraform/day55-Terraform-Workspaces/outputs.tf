output "active_workspace" {
  value = terraform.workspace
}

output "file_path" {
  value = local_file.environment.filename
}
