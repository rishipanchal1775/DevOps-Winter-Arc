resource "local_file" "this" {
  filename = var.filename
  content  = "${var.environment}: ${var.content}"
}
