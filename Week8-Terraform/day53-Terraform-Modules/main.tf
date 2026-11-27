terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

module "report_file" {
  source      = "./modules/text_file"
  filename    = "${path.module}/report.txt"
  content     = "Created by a reusable Terraform module."
  environment = "development"
}

module "test_file" {
  source      = "./modules/text_file"
  filename    = "${path.module}/test.txt"
  content     = "This is the second module call."
  environment = "testing"
}
