terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "environments" {
  type = map(string)

  default = {
    dev  = "Development environment"
    test = "Testing environment - updated"
    qa   = "Quality assurance environment"
  }
}

resource "local_file" "environment" {
  for_each = var.environments

  filename = "${path.module}/${each.key}.txt"
  content  = "${upper(each.key)}: ${each.value}"
}

locals {
  environment_count = length(var.environments)

  environment_names = [for name, description in var.environments : upper(name)]

  production_label = lookup(var.environments, "prod", "") == "Production environment" ? "Production" : "Non-production"
}
