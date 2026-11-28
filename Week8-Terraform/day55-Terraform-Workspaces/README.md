# Day 55 — Terraform Workspaces & Environments

## Objective

Learn how Terraform workspaces maintain separate state instances for one configuration. Practise creating and switching workspaces, using workspace-aware naming, and passing environment-specific values.

**Lab safety:** This lab uses local files only. It does not create AWS resources or incur cloud charges.

## Topics Covered

- Terraform workspaces and their purpose
- Default and named workspaces
- Workspace commands: `list`, `new`, `select`, `show`, and `delete`
- Separate state instances for each workspace
- Using `terraform.workspace` in configuration
- Workspace-specific values and naming
- Workspaces compared with separate directories/configurations
- Why workspaces alone are not a production security boundary

## Project Structure

Create the project folder:

```bash
mkdir -p day55-terraform-workspaces
cd day55-terraform-workspaces
touch main.tf outputs.tf
```

The project contains:

```text
day55-terraform-workspaces/
├── main.tf
└── outputs.tf
```

## 1. Terraform Configuration

### `main.tf`

```hcl
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
  content  = "This file belongs to ${terraform.workspace}."
}
```

The `terraform.workspace` expression returns the name of the currently selected workspace. The filename therefore changes with the workspace.

### `outputs.tf`

```hcl
output "active_workspace" {
  value = terraform.workspace
}

output "file_path" {
  value = local_file.environment.filename
}
```

## 2. Initialize and Validate

Run these commands from the project folder:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform workspace list
```

The initial workspace is `default`. The workspace list displays the available workspaces, with the active workspace marked.

## 3. Create and Apply the `dev` Workspace

Create and select the development workspace:

```bash
terraform workspace new dev
terraform workspace show
terraform plan
terraform apply
```

Review the plan before confirming the apply.

Verify the file was created:

```bash
ls -l
cat dev.txt
terraform state list
terraform output
```

Expected file content:

```text
This file belongs to dev.
```

## 4. Create and Apply the `test` Workspace

Create and select the test workspace:

```bash
terraform workspace new test
terraform workspace show
terraform plan
terraform apply
```

Review the plan before confirming the apply.

Verify the test file and the available workspaces:

```bash
ls -l
cat test.txt
terraform state list
terraform output
terraform workspace list
```

Expected file content:

```text
This file belongs to test.
```

The `dev` and `test` workspaces use the same configuration but maintain separate Terraform state instances. Each workspace tracks its own managed file.

Switch back to `dev` and inspect its state:

```bash
terraform workspace select dev
terraform workspace show
terraform state list
terraform output
```

## 5. Environment-Specific Message Challenge

Update `main.tf` to include a variable and use it as the file content:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

variable "environment_message" {
  description = "Message written to the environment file"
  type        = string
}

resource "local_file" "environment" {
  filename = "${path.module}/${terraform.workspace}.txt"
  content  = var.environment_message
}
```

Keep `outputs.tf` as shown above.

Create a `dev.tfvars` file:

```hcl
environment_message = "This is the development environment."
```

Create a `test.tfvars` file:

```hcl
environment_message = "This is the test environment."
```

Apply the matching values in each workspace:

```bash
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
cat dev.txt
```

```bash
terraform workspace select test
terraform plan -var-file="test.tfvars"
terraform apply -var-file="test.tfvars"
cat test.txt
```

The generated files should contain their respective environment messages.

## 6. Workspace State Diagram

```text
              One Terraform configuration
                         |
             +-----------+-----------+
             |           |           |
          default        dev        test
             |           |           |
          State       State       State
             |           |           |
        default.txt    dev.txt    test.txt
```

Each workspace has its own state instance, while the configuration is shared.

## 7. Important Concepts

### What are Terraform workspaces?

Workspaces allow one Terraform configuration to manage separate state instances. They are useful for simple testing and basic environment separation.

### Default and named workspaces

- `default` is the initial workspace.
- Named workspaces, such as `dev` and `test`, can be created and selected as needed.

### Workspaces versus separate directories/configurations

Workspaces share one configuration but maintain separate state instances. Separate directories or configurations provide independent configuration and state boundaries and can be clearer when environments differ significantly.

### Are workspaces a production security boundary?

No. Workspaces do not automatically provide separate credentials, access controls, or strong isolation. Production environments may require separate state storage, permissions, and configurations.

## 8. Useful Workspace Commands

| Command | Purpose |
|---|---|
| `terraform workspace list` | List available workspaces |
| `terraform workspace new dev` | Create and select the `dev` workspace |
| `terraform workspace select dev` | Switch to `dev` |
| `terraform workspace show` | Display the current workspace |
| `terraform workspace delete dev` | Delete an empty workspace |

## 9. Interview Questions and Answers

**What is a Terraform workspace?**  
A separate state instance for the same Terraform configuration.

**What is the default workspace?**  
The initial workspace Terraform uses unless another workspace is selected.

**How do you create and switch workspaces?**  
Use `terraform workspace new <name>` to create and select one, or `terraform workspace select <name>` to switch to an existing workspace.

**What does `terraform.workspace` return?**  
The name of the currently selected workspace.

**Does each workspace have its own state?**  
Yes. Each workspace maintains a separate state instance.

**Are workspaces a complete security boundary?**  
No. They do not automatically separate credentials, permissions, or provide strong isolation.

**When would you use separate directories instead?**  
When environments differ significantly or need independent configuration and state boundaries.

## 10. Cleanup

Destroy the resources in each workspace before deleting the workspaces.

In `dev`:

```bash
terraform workspace select dev
terraform destroy
```

In `test`:

```bash
terraform workspace select test
terraform destroy
```

Review each destroy plan and confirm before proceeding.

Switch to `default`, then delete the now-empty workspaces:

```bash
terraform workspace select default
terraform workspace delete dev
terraform workspace delete test
terraform workspace list
```

**Never delete a workspace that is still managing resources.**

## Safety Notes

- This lab creates local text files only; no cloud resources or AWS charges.
- Do not store secrets in workspace names, configuration files, or Git commits.
- Workspaces do not replace appropriate production access controls or environment isolation.
