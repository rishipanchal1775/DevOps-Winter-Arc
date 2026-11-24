output "created_file_path" {
  value = local_file.demo.filename
}

output "project_environment" {
  value = "${var.project_name} / ${var.environment}"
}
