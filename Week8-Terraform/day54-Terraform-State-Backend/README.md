# Day 54 — Terraform State and Backend

## Objective

Understand how Terraform tracks infrastructure, inspect state safely, and learn how local and remote backends work. This lab uses the local-file resources from Day 53, so it does not require AWS resources or create cloud charges.

## 1. What Is Terraform State?

Terraform state is a record of the infrastructure Terraform manages. It stores information about resources that Terraform has created and connects those resources to the configuration in the Terraform project.

Terraform uses state to understand what already exists and determine what needs to be created, changed, or removed when I run `terraform plan` or `terraform apply`.

The state file is usually named `terraform.tfstate` when using the local backend. It can contain resource details and sensitive values, so I must treat it as private information.

## 2. Day 53 Project and Lab Commands

I use my Day 53 local-file module project:

```bash
cd ~/DevOps-Winter-Arc/Week8-Terraform/day53-Terraform-Modules
```

### Initialize Terraform

```bash
terraform init
```

This initializes the working directory and downloads or prepares the providers and modules needed by the configuration. I run it when I first set up the project or when the backend configuration changes.

### Preview the changes

```bash
terraform plan
```

This shows the changes Terraform intends to make. It lets me review the proposed actions before applying them.

### Apply the configuration

```bash
terraform apply
```

This applies the planned configuration and creates or updates the resources. In this lab, the resources are local files.

### List resources tracked in state

```bash
terraform state list
```

This lists the resource addresses Terraform currently tracks in its state. In my Day 53 project, the addresses include:

```text
module.report_file.local_file.this
module.test_file.local_file.this
```

### Inspect a resource

```bash
terraform state show module.report_file.local_file.this
```

This displays the state details for the selected resource. I use the exact resource address returned by `terraform state list`.

### Pull the current state

```bash
terraform state pull
```

This prints the current state data. The output may contain sensitive values, so I do not share it publicly or include unredacted output in screenshots.

### Show Terraform's view of the resources

```bash
terraform show
```

This displays a human-readable view of the current state.

## 3. State Management Exercises

### List resources tracked in state

I use:

```bash
terraform state list
```

The command shows which resources Terraform currently tracks. A resource address can include module names, so I copy the exact address from the output before inspecting a resource.

### Inspect one resource

I use:

```bash
terraform state show module.report_file.local_file.this
```

This shows the stored details for that resource. It helps me understand what Terraform has recorded about a particular resource.

### Back up the state file

Before experimenting with state, I make a backup:

```bash
cp terraform.tfstate terraform.tfstate.day54-backup
ls -l terraform.tfstate*
```

The `cp` command creates a separate copy of the state file. The `ls` command lets me check that the state file and backup are present.

State files and backups can contain sensitive information. I keep them local and do not commit them to GitHub or upload them.

### What can happen if state is lost or manually changed?

If Terraform state is lost, Terraform may no longer know which real resources belong to the configuration. It could propose creating resources again or show unexpected changes. The actual resources may still exist even if Terraform has lost its record of them.

If state is manually changed, its recorded information can stop matching the real resources. This can cause incorrect plans or unexpected changes. I never edit `terraform.tfstate` JSON manually.

### What does `terraform state mv` do?

`terraform state mv` changes the address of a resource recorded in state. It is useful when I rename a resource or move it into a module and want Terraform to keep tracking the same existing resource under its new address.

Example syntax:

```bash
terraform state mv OLD_RESOURCE_ADDRESS NEW_RESOURCE_ADDRESS
```

I research the correct addresses before using this command. I do not run it on important infrastructure as part of this lab.

### What does `terraform state rm` do?

`terraform state rm` removes a resource's record from Terraform state. It does **not** destroy the real resource. The resource can continue to exist, but Terraform will no longer track it at that address.

Example syntax:

```bash
terraform state rm RESOURCE_ADDRESS
```

I do not run this command on important infrastructure. Removing a resource from state can cause Terraform to treat it as unmanaged.

## 4. Backend Concepts

### What is a backend?

A backend determines where Terraform stores its state and how Terraform accesses it. Terraform needs state to keep track of the resources managed by a configuration.

### Local backend

The local backend stores state in a file on the machine where Terraform is run. It is simple for an individual lab or local project.

For this lab, I use the local backend and local-file resources. I do not need to configure a cloud backend.

### Remote backend

A remote backend stores state in a remote location instead of only on a local machine. It can make the same state available to a team, which helps team members work with a shared infrastructure configuration.

Remote state needs careful security controls because it can contain sensitive information.

### Local backend vs. remote backend

| Local backend | Remote backend |
|---|---|
| Stores state locally, usually in `terraform.tfstate`. | Stores state in a remote system. |
| Convenient for an individual local lab. | Supports shared access for team workflows. |
| State access and backups depend on local file handling. | Requires secure remote access, encryption, and backups. |
| Collaboration and concurrent access need extra care. | Some remote backends provide state locking for collaboration. |

### What is state locking?

State locking prevents multiple Terraform operations from modifying the same state at the same time. This helps avoid conflicting changes or state corruption when multiple people or processes are working with the same state.

Locking support depends on the backend. I should check whether the selected backend supports it rather than assume every backend does.

### Why remote state needs protection

Remote state may contain sensitive values. It should be protected with encryption, restricted access, and backups. Only people and systems that need the state should be allowed to access it.

I never commit state files, state backups, or secret `.tfvars` files to GitHub. I also never put credentials directly into Terraform source code.

## 5. S3 Backend Reference Example — Do Not Apply

The following is a reference example from the assignment. I am studying what the settings mean; I am **not** creating an S3 bucket or applying this configuration.

```hcl
terraform {
  backend "s3" {
    bucket = "EXISTING-BUCKET-NAME"
    key    = "day54/terraform.tfstate"
    region = "ap-south-1"
  }
}
```

- `bucket` is the name of the existing S3 bucket where Terraform would store the state.
- `key` is the path or name used for the state object inside that bucket.
- `region` is the AWS region where the bucket is located. In this example, it is `ap-south-1`.

A backend configuration change requires running:

```bash
terraform init
```

Terraform may ask whether I want to migrate existing state to the new backend. I should understand the change and review the migration prompt before proceeding. I do not apply the S3 example for this local assignment.

## 6. Interview Questions and Answers

### What is Terraform state?

Terraform state is Terraform's record of the resources it manages. It connects the resources in my configuration to the resources Terraform has created or is tracking.

### Why does Terraform maintain a state file?

Terraform maintains state so it can remember the resources it manages and compare the recorded information with the configuration. This helps Terraform decide what changes are needed during a plan or apply.

### What is a backend?

A backend tells Terraform where and how to store and access its state.

### What is the difference between a local and remote backend?

A local backend stores state in a local file. A remote backend stores state in a remote location and can support shared team access. Remote state needs proper access control, encryption, and backups.

### What is state locking?

State locking prevents concurrent Terraform operations from changing the same state at the same time. It helps protect state when multiple people or processes are working with it. Locking support depends on the backend.

### Why must state files be protected?

State files can contain sensitive information. I should restrict access, use encryption where appropriate, keep backups secure, and never commit state files or backups to GitHub.

### What do `terraform state mv` and `terraform state rm` do?

`terraform state mv` changes a resource's address in state, such as when I rename a resource or move it into a module. `terraform state rm` removes a resource's record from state but does not destroy the real resource.

### What does `terraform state pull` do?

`terraform state pull` prints the current state data. Since the output may contain sensitive values, I keep it private and hide sensitive information before taking or sharing a screenshot.

## 7. Cleanup

The assignment asks me to destroy the local lab resources and confirm the operation. I use:

```bash
terraform destroy
```

I review the proposed actions and confirm only when I am ready to remove the local lab resources. I keep my notes and screenshots, but I do not upload the state file or its backup.

## Important Safety Notes

- Never edit `terraform.tfstate` manually.
- Treat state files and backups as sensitive.
- Do not commit state files, backups, or secret `.tfvars` files to GitHub.
- Restrict access to remote state and enable encryption.
- Do not paste credentials into Terraform source code.
- Do not create an S3 bucket or apply the S3 backend example for this assignment.
