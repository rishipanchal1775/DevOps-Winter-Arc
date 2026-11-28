terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "demo" {
  filename = "${path.module}/day56.txt"
  content  = "Terraform lifecycle practice"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [content]
  }

  provisioner "local-exec" {
    command = "echo Terraform created the file"
  }
}
