output "generated_file" {
  value = module.report_file.file_path
}

output "generated_file_content" {
  value = module.report_file.file_content
}
