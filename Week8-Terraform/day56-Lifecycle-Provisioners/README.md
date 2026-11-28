# Day 56 — Terraform Lifecycle & Provisioners

## Overview

**Objective:** Understand how Terraform creates, updates, replaces, and destroys resources. Practise lifecycle meta-arguments and learn when provisioners are appropriate.

This lab uses Terraform's **local provider** and a local shell command. It does not create AWS resources, connect to a server, or incur cloud charges.

## Lab Environment

- **Folder:** `day56-Lifecycle-Provisioners`
- **Terraform resource:** `local_file.demo`
- **File created:** `day56.txt`
- **Provider:** `hashicorp/local`, version `~> 2.5`

## 1. Concepts

### Terraform resource lifecycle

Terraform manages resources through these common operations:

- **Create:** Create a resource that is declared in configuration but does not yet exist.
- **Update:** Change an existing resource when its provider supports an in-place update.
- **Replace:** Destroy and recreate a resource when a change cannot be applied in place.
- **Destroy:** Remove a managed resource when it is removed from configuration or when `terraform destroy` is run.

Some resource attributes are immutable. Changing an immutable attribute can require Terraform to replace the resource rather than update it.

### Lifecycle meta-arguments

| Meta-argument | Purpose | Important consideration |
|---|---|---|
| `create_before_destroy` | Requests that Terraform create the replacement before destroying the old resource. | The old and new instances must be able to coexist. |
| `prevent_destroy` | Blocks Terraform plans that would destroy the resource while this rule remains in configuration. | It is a guardrail, not a backup. Remove the rule when intentionally destroying the resource. |
| `ignore_changes` | Tells Terraform to ignore changes to selected attributes when planning updates to an existing resource. | It can hide configuration drift, so use it carefully. |

## 2. Create the Lab Configuration

Create or open `main.tf` in the lab folder:

```hcl
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
}
```

Initialize the working directory:

```bash
terraform init
```

Check the configuration:

```bash
terraform validate
```

Review the planned changes:

```bash
terraform plan
```

Apply the configuration:

```bash
terraform apply
```

When prompted, enter `yes`.

Confirm the file exists and inspect its contents:

```bash
ls -l day56.txt
cat day56.txt
```

Expected file content:

```text
Terraform lifecycle practice
```

## 3. Lifecycle Experiments

### Experiment A — `ignore_changes`

1. Apply the configuration from Section 2.
2. Manually change the file:

   ```bash
   echo "Manually changed content" > day56.txt
   ```

3. Check the file:

   ```bash
   cat day56.txt
   ```

4. Run a plan:

   ```bash
   terraform plan
   ```

**Observation:** Because `content` is listed in `ignore_changes`, Terraform ignores the content difference for this existing resource. The plan should not propose changing the file content back to the configured value.

**What this demonstrates:** `ignore_changes` can be useful when an attribute is intentionally managed outside Terraform, but it can also conceal drift between configuration and the real resource.

Record the relevant output from your own `terraform plan` here:

```text
[Paste your plan output here]
```

### Experiment B — `prevent_destroy`

Add `prevent_destroy = true` to the lifecycle block:

```hcl
lifecycle {
  create_before_destroy = true
  ignore_changes        = [content]
  prevent_destroy       = true
}
```

Run:

```bash
terraform plan
terraform destroy
```

Terraform should block the destroy operation while `prevent_destroy` is present in the resource configuration. Record the result from your terminal:

```text
[Paste the destroy result here]
```

**Important:** Remove `prevent_destroy = true` before cleanup. This setting prevents a planned destroy while it is configured, but it does not protect against every possible loss scenario and is not a backup strategy.

### Experiment C — `create_before_destroy`

`create_before_destroy = true` asks Terraform to create a replacement before removing the existing resource. This can reduce downtime when both instances can exist at the same time.

It may not work when the resource or external system requires a unique name, address, or other property that prevents the old and new instances from coexisting. In that situation, Terraform may be unable to create the replacement first.

## 4. Provisioners — Local Demo

Provisioners run commands during resource lifecycle events. They should generally be treated as a last resort because their behavior can make Terraform runs less predictable.

Add this block **inside** the `local_file.demo` resource:

```hcl
provisioner "local-exec" {
  command = "echo Terraform created the file"
}
```

Apply the configuration:

```bash
terraform apply
```

A `local-exec` provisioner runs a command on the machine where Terraform is running. When the resource is created, the command prints:

```text
Terraform created the file
```

**Recorded lab output:** The local-exec command ran during resource creation and printed the message above.

```text
[Paste or attach your apply output here]
```

### `local-exec` vs. `remote-exec`

- **`local-exec`:** Runs a command on the machine running Terraform. This lab uses it to print a message locally.
- **`remote-exec`:** Runs commands on a remote machine. It requires a reachable remote host and connection details so Terraform can connect to that machine.

This lab does not configure SSH credentials or run commands on a real server.

### Provisioner options to know

- `when = create` runs a provisioner during resource creation; this is the default behavior.
- `when = destroy` runs a provisioner during resource destruction.
- `on_failure` controls how Terraform handles a provisioner failure.

Provisioners are not a replacement for configuration-management or application-bootstrap systems. Prefer native provider resources or appropriate bootstrap/configuration tools when possible.

## 5. Safer Alternatives to Provisioners

Consider these alternatives before using a provisioner:

- Use native Terraform provider resources to manage infrastructure directly.
- Use cloud-init or user data for supported machine bootstrap tasks.
- Use configuration-management tools for ongoing system configuration.
- Keep application deployment and configuration management separate from Terraform infrastructure provisioning where appropriate.

## 6. Interview Questions and Answers

### What is the Terraform resource lifecycle?

It is the process Terraform uses to create, update, replace, and destroy resources according to configuration and state.

### What does `create_before_destroy` do?

It requests that Terraform create a replacement resource before destroying the existing one. This may reduce downtime when both resources can coexist.

### When is `prevent_destroy` useful?

It is a guardrail for resources that should not be accidentally destroyed through a Terraform plan while the rule is configured. It is not a backup.

### What is the risk of `ignore_changes`?

Terraform may stop reporting or correcting differences in the ignored attributes. This can hide configuration drift.

### What is a provisioner?

A provisioner runs a command or script at a resource lifecycle event, such as creation or destruction.

### What is the difference between `local-exec` and `remote-exec`?

`local-exec` runs on the machine executing Terraform. `remote-exec` runs on a remote machine and requires a reachable host and connection details.

### Why should provisioners generally be avoided?

They can make Terraform runs less predictable and are not a replacement for native provider resources, bootstrap tools, or configuration-management tools.

## 7. Cleanup

First, ensure `prevent_destroy` is **not** present in the lifecycle block. Then run:

```bash
terraform destroy
```

Enter `yes` when prompted.

Confirm that Terraform removed the local file:

```bash
ls -l day56.txt
```

The file should no longer exist. If `ls` reports that it cannot access `day56.txt`, that confirms the file was removed.

## Safety and Cost

This lab uses local files and a local shell command only. No AWS resources, SSH connections, real servers, or cloud charges are required.
