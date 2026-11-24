resource "local_file" "demo" {
  filename = local.output_filename
  content  = var.message
}
