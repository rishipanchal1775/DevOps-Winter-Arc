terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "local" {}

variable "project_name" {
  type    = string
  default = "terraform-day51-updated"
}

resource "local_file" "welcome" {
  filename = "${path.module}/hello.txt"
  content  = "Hello from Terraform: ${var.project_name}"
}

output "created_file_path" {
  value = local_file.welcome.filename
}
