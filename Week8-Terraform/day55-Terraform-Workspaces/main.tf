terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

resource "local_file" "environment" {
  filename = "${path.module}/${terraform.workspace}.txt"
  content = var.environment_message
}

variable "environment_message" {
  description = "Message written into the environment file"
  type        = string
}
