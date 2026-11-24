# Day 52 — Terraform Variables, Outputs & Data Sources

## Overview

In Day 52 of the DevOps Winter Arc, we learn how to make Terraform configurations reusable and flexible using input variables, local values, output values, and data sources.

In Day 51, we created a local text file using Terraform's Local Provider. In Day 52, we improve that configuration by separating it into multiple files and controlling the filename and file content through input variables.

This practical lab uses the **Local Provider** only. No AWS infrastructure is created, and no cloud charges are involved.

### Learning Objectives

By completing this lab, you will learn:

- Understand input variables and their purpose.
- Define variable descriptions, types, defaults, and validation rules.
- Pass variable values through `terraform.tfvars`, custom `.tfvars` files, and CLI flags.
- Understand variable precedence.
- Understand sensitive variables and sensitive outputs.
- Use local values (`locals`) to calculate reusable values.
- Understand Terraform output values.
- Understand data sources and how they read existing information.
- Differentiate between resources and data sources.
- Differentiate between variables and locals.
- Differentiate between inputs and outputs.
- Modify variable values and observe Terraform's proposed changes.

---

## 1. What Are Terraform Input Variables?

Input variables allow us to pass values into Terraform configurations from outside the resource definitions.

They make Terraform configurations reusable, flexible, and easier to maintain.

Without variables, we might hardcode values directly inside resource blocks.

For example:

```hcl
resource "local_file" "demo" {
  filename = "day52-practice.txt"
  content  = "Hello from Terraform"
}
```

If we want to change the filename or content, we must edit the resource configuration itself.

Using variables, we can make the configuration reusable:

```hcl
variable "project_name" {
  type    = string
  default = "day52"
}

variable "environment" {
  type    = string
  default = "practice"
}
```

Now the values can be supplied separately without changing the resource definition.

### Advantages of Input Variables

1. **Reusability:** Use the same Terraform configuration with different values.
2. **Flexibility:** Change input values without rewriting resource blocks.
3. **Maintainability:** Keep configuration logic separate from environment-specific values.
4. **Consistency:** Reuse the same configuration across development, testing, and production environments.
5. **Customization:** Allow users to provide their own values.

---

## 2. Fundamental Terraform Variable Concepts

### 2.1 Variable Declaration

A variable is declared using the `variable` block.

Example:

```hcl
variable "project_name" {
  type        = string
  description = "Name of the Terraform project"
  default     = "winter-arc"
}
```

Explanation:

- `variable` declares an input variable.
- `project_name` is the variable name.
- `type` specifies the expected data type.
- `description` explains the variable's purpose.
- `default` defines the value used when no higher-precedence value is supplied.

### 2.2 Variable Types

Terraform supports different data types.

| Type | Meaning | Example |
|---|---|---|
| `string` | Text value | `"development"` |
| `number` | Numeric value | `10` |
| `bool` | Boolean value | `true` |
| `list(string)` | List of strings | `["dev", "test"]` |
| `set(string)` | Collection of unique strings | `["dev", "test"]` |
| `map(string)` | Key-value collection | `{ env = "dev" }` |
| `object` | Structured collection of named attributes | `{ name = "app", port = 8080 }` |

Example of a number variable:

```hcl
variable "instance_count" {
  type    = number
  default = 2
}
```

Example of a Boolean variable:

```hcl
variable "enable_monitoring" {
  type    = bool
  default = true
}
```

Example of a list variable:

```hcl
variable "environments" {
  type    = list(string)
  default = ["development", "testing", "production"]
}
```

### 2.3 Variable Validation

Variable validation allows us to define rules that input values must satisfy.

For example:

```hcl
variable "environment" {
  type        = string
  description = "Deployment environment"

  validation {
    condition     = contains(["development", "testing", "production"], var.environment)
    error_message = "Environment must be development, testing, or production."
  }
}
```

Explanation:

- `validation` defines a condition.
- `contains()` checks whether the supplied environment exists in the allowed list.
- `error_message` displays an error if the condition is false.

This helps prevent invalid input values.

### 2.4 Variable Descriptions

A description explains the purpose of a variable.

Example:

```hcl
variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "winter-arc"
}
```

Descriptions improve readability and help other team members understand the configuration.

---

## 3. Ways to Supply Terraform Variable Values

Terraform allows variables to receive values from different sources.

### 3.1 Default Values

A default value is declared inside the variable block.

```hcl
variable "environment" {
  type    = string
  default = "development"
}
```

If no other value is supplied, Terraform uses `development`.

### 3.2 terraform.tfvars

Terraform automatically loads a file named:

```text
terraform.tfvars
```

Example:

```hcl
project_name = "day52"
environment  = "practice"
message      = "Hello from Terraform"
```

These values override the corresponding variable defaults.

### 3.3 Custom .tfvars Files

We can create custom variable files.

Example:

```text
testing.tfvars
```

Contents:

```hcl
project_name = "day52"
environment  = "testing"
message      = "Testing environment"
```

To use this file:

```bash
terraform plan -var-file="testing.tfvars"
```

To apply:

```bash
terraform apply -var-file="testing.tfvars"
```

### 3.4 Command-Line Variables

We can also pass variable values directly through the CLI.

Example:

```bash
terraform plan -var="environment=testing"
```

To apply:

```bash
terraform apply -var="environment=testing"
```

### 3.5 Environment Variables

Terraform can also read input variables from environment variables that follow this naming pattern:

```text
TF_VAR_variable_name
```

Example:

```bash
export TF_VAR_environment="testing"
```

Terraform can use this value for the `environment` input variable when no higher-precedence source overrides it.

---

## 4. Terraform Variable Precedence

If the same variable receives values from multiple sources, Terraform follows a precedence order.

For the common variable sources used in this lab, the general order from lower to higher precedence is:

1. Variable default values.
2. `terraform.tfvars` and `terraform.tfvars.json`.
3. Automatically loaded `*.auto.tfvars` and `*.auto.tfvars.json` files.
4. Environment variables such as `TF_VAR_environment`.
5. Explicit `-var` and `-var-file` command-line arguments.

When multiple automatically loaded files or command-line arguments define the same variable, their loading or argument order also matters.

**Important:** The higher-precedence supplied value is used instead of the lower-precedence value.

Example:

Variable default:

```hcl
variable "environment" {
  type    = string
  default = "development"
}
```

Value in `terraform.tfvars`:

```hcl
environment = "practice"
```

CLI command:

```bash
terraform plan -var="environment=testing"
```

The CLI value `testing` takes precedence over the default and the value in `terraform.tfvars`.

---

## 5. Sensitive Variables

Sensitive variables are used to mark values that should not be displayed in normal Terraform CLI output.

Example:

```hcl
variable "database_password" {
  type      = string
  sensitive = true
}
```

The `sensitive = true` setting tells Terraform to redact the value in many normal displays.

### Why Do We Use Sensitive Variables?

Examples include:

- Database passwords.
- API tokens.
- Authentication secrets.
- Private credentials.

### Important Security Note

Marking a variable as sensitive does not automatically encrypt it or remove it from Terraform state.

Sensitive values may still be stored in state files and other Terraform data.

Therefore:

- Never commit passwords or API keys to GitHub.
- Never publish secret `.tfvars` files.
- Protect Terraform state files.
- Use secure secret-management systems for real infrastructure projects.

---

## 6. Terraform Local Values (locals)

Local values allow us to assign a name to an expression that can be reused inside Terraform configuration.

They are useful when we want to calculate or combine values.

Example:

```hcl
locals {
  output_filename = "${var.project_name}-${var.environment}.txt"
}
```

Explanation:

- `locals` declares local values.
- `output_filename` is the local value name.
- `${var.project_name}` references an input variable.
- `${var.environment}` references another input variable.

If the input values are:

```hcl
project_name = "day52"
environment  = "practice"
```

The calculated local value becomes:

```text
day52-practice.txt
```

### Why Use Locals?

- Avoid repeating the same expressions.
- Store calculated values.
- Make configuration easier to read.
- Combine multiple input values into one reusable value.

### Variable vs Local

| Variable | Local |
|---|---|
| Accepts input values | Defines internal values |
| Can receive values from external sources | Defined inside Terraform configuration |
| Can have a default value | Uses an expression or assigned value |
| Accessed using `var.name` | Accessed using `local.name` |

Example:

```hcl
var.project_name
```

```hcl
local.output_filename
```

---

## 7. Terraform Output Values

Output values allow Terraform to display useful information after configuration is evaluated and applied.

Example:

```hcl
output "created_file_path" {
  value = local_file.demo.filename
}
```

Explanation:

- `output` declares an output block.
- `created_file_path` is the output name.
- `value` specifies the information to display.

Another example:

```hcl
output "project_environment" {
  value = "${var.project_name} / ${var.environment}"
}
```

This displays the project name and environment together.

### Display Outputs

Run:

```bash
terraform output
```

To display one output:

```bash
terraform output created_file_path
```

### Sensitive Outputs

An output can also be marked sensitive:

```hcl
output "database_password" {
  value     = var.database_password
  sensitive = true
}
```

This marks the output as sensitive and hides it in normal output displays.

However, the value can still exist in Terraform state. Sensitive outputs are not a replacement for secure state storage.

---

## 8. Terraform Data Sources

A data source allows Terraform to read information about an existing object without managing its lifecycle like a resource.

For example:

- A resource can create a local file.
- A data source can read information about an existing local file.

### Resource vs Data Source

| Resource | Data Source |
|---|---|
| Creates and manages an object | Reads information about an existing object |
| Manages the object's lifecycle | Does not manage that object's lifecycle |
| Declared using `resource` | Declared using `data` |
| Can create, update, or destroy managed objects | Retrieves information for use in configuration |

Resource example:

```hcl
resource "local_file" "demo" {
  filename = "example.txt"
  content  = "Hello Terraform"
}
```

Data source syntax example:

```hcl
data "local_file" "existing" {
  filename = "${path.module}/example.txt"
}
```

The second example is a reference to the Local Provider's `local_file` data source. It reads an existing file rather than creating or managing its lifecycle.

### Data Source Reference Task

The Day 52 PDF asks us to find one suitable data source in the official Terraform Registry and document its arguments and returned attributes.

A suitable reference example is the Local Provider's `local_file` data source.

Official documentation:

[Terraform Registry — Local Provider: local_file Data Source](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file)

**Arguments:**

| Argument | Purpose |
|---|---|
| `filename` | Path of the existing file to read |

**Returned attributes:**

| Attribute | Purpose |
|---|---|
| `content` | Contents of the file |
| `content_base64` | Base64-encoded contents |
| `content_sha256` | SHA-256 checksum of the file |
| `filename` | Path of the file |
| `id` | Identifier associated with the data source |

Example reference configuration:

```hcl
data "local_file" "existing" {
  filename = "${path.module}/example.txt"
}

output "existing_file_content" {
  value = data.local_file.existing.content
}
```

This example is a **reference example**, not an executed part of the required lab unless it is separately tested.

A data source must be able to read the existing file when Terraform evaluates it.

---

## 9. Day 52 Practical Lab — Reusable Local Configuration

### Objective

Create a local text file whose filename and content are controlled by Terraform input variables.

The project uses the Local Provider and does not create AWS resources.

### Step 1 — Create the Project Directory

```bash
mkdir -p ~/DevOps-Winter-Arc/day52-terraform-inputs
```

Navigate into the directory:

```bash
cd ~/DevOps-Winter-Arc/day52-terraform-inputs
```

Verify:

```bash
pwd
```

### Step 2 — Create the Project Structure

The required folder structure is:

```text
day52-terraform-inputs/
├── versions.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
└── terraform.tfvars
```

We separate the configuration into multiple files to make the project easier to understand and maintain.

### Step 3 — Create versions.tf

```bash
nano versions.tf
```

Add:

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
```

Explanation:

This block declares the required Local Provider and its version constraint.

Save the file.

### Step 4 — Create variables.tf

```bash
nano variables.tf
```

Add:

```hcl
variable "project_name" {
  type    = string
  default = "winter-arc"
}

variable "environment" {
  type    = string
  default = "development"
}

variable "message" {
  type    = string
  default = "Terraform Day 52 lab"
}
```

Explanation:

This file defines three input variables.

- `project_name`: Name of the project.
- `environment`: Environment name.
- `message`: Text that will be written into the generated file.

All three variables use the string data type.

Save the file.

### Step 5 — Create locals.tf

```bash
nano locals.tf
```

Add:

```hcl
locals {
  output_filename = "${var.project_name}-${var.environment}.txt"
}
```

Explanation:

This local value combines the project name and environment to calculate the output filename.

For example:

```text
day52-practice.txt
```

Save the file.

### Step 6 — Create main.tf

```bash
nano main.tf
```

Add:

```hcl
resource "local_file" "demo" {
  filename = local.output_filename
  content  = var.message
}
```

Explanation:

- `local_file` is the resource type.
- `demo` is the resource name.
- `filename` uses the calculated local value.
- `content` uses the input message variable.

Terraform will create a local text file using these values.

Save the file.

### Step 7 — Create outputs.tf

```bash
nano outputs.tf
```

Add:

```hcl
output "created_file_path" {
  value = local_file.demo.filename
}

output "project_environment" {
  value = "${var.project_name} / ${var.environment}"
}
```

Explanation:

The first output displays the generated file path.

The second output displays the project name and environment.

Save the file.

### Step 8 — Create terraform.tfvars

```bash
nano terraform.tfvars
```

Add the values specified in the Day 52 PDF:

```hcl
project_name = "day52"
environment  = "practice"
message      = "Hello from Terraform variables and outputs!"
```

Explanation:

This file provides the actual input values for the variables.

Terraform automatically loads `terraform.tfvars`.

Save the file.

### Step 9 — Verify Project Files

```bash
ls -la
```

Expected project files:

```text
versions.tf
variables.tf
locals.tf
main.tf
outputs.tf
terraform.tfvars
```

Terraform may create additional files and directories after initialization.

---

## 10. Initialize, Format, Validate, and Apply

### Step 1 — Initialize Terraform

```bash
terraform init
```

This initializes the project and downloads the Local Provider.

### Step 2 — Format All Terraform Files

```bash
terraform fmt -recursive
```

This formats Terraform configuration files recursively.

### Step 3 — Validate Configuration

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

### Step 4 — Review Terraform Plan

```bash
terraform plan
```

Terraform should propose creating one resource:

```text
local_file.demo
```

The filename should be:

```text
day52-practice.txt
```

The content should be:

```text
Hello from Terraform variables and outputs!
```

Expected plan summary:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

The exact output may vary.

Always review the proposed changes before applying.

### Step 5 — Apply Terraform Configuration

```bash
terraform apply
```

Review the plan and type:

```text
yes
```

Only if the plan shows the expected creation of the single local file resource.

Terraform creates:

```text
day52-practice.txt
```

### Step 6 — Verify the Generated File

```bash
ls -l
```

Read the file:

```bash
cat day52-practice.txt
```

Expected content:

```text
Hello from Terraform variables and outputs!
```

### Step 7 — Verify Terraform Outputs

```bash
terraform output
```

Expected values:

```text
created_file_path = "day52-practice.txt"
project_environment = "day52 / practice"
```

The exact formatting may vary depending on the Terraform version.

---

## 11. Change at Least Two Variables and Observe the Changes

### Objective

Modify at least two values in `terraform.tfvars`, then run Terraform plan and apply again.

This demonstrates how Terraform uses input variables to update managed resources.

### Step 1 — Open terraform.tfvars

```bash
nano terraform.tfvars
```

Original values:

```hcl
project_name = "day52"
environment  = "practice"
message      = "Hello from Terraform variables and outputs!"
```

Change them to:

```hcl
project_name = "day52-updated"
environment  = "testing"
message      = "Day 52: Updated Terraform configuration successfully!"
```

We have changed all three values, satisfying the requirement to change at least two.

Save the file.

### Step 2 — Generate a New Plan

```bash
terraform plan
```

Terraform compares the new configuration with its existing state.

Previously, the generated filename was:

```text
day52-practice.txt
```

Now the calculated filename becomes:

```text
day52-updated-testing.txt
```

The file content also changes.

Because the filename changes, the Local Provider generally proposes replacing the existing file resource.

Review the plan carefully before proceeding.

### Step 3 — Apply the Updated Configuration

```bash
terraform apply
```

Review the plan again.

Type `yes` only if the proposed actions match the expected changes to `local_file.demo`.

### Step 4 — Verify the Updated File

```bash
ls -l
```

Read the new file:

```bash
cat day52-updated-testing.txt
```

Expected content:

```text
Day 52: Updated Terraform configuration successfully!
```

### Step 5 — Verify Updated Outputs

```bash
terraform output
```

Expected values:

```text
created_file_path = "day52-updated-testing.txt"
project_environment = "day52-updated / testing"
```

### Before and After Comparison

| Attribute | Before | After |
|---|---|---|
| Project name | day52 | day52-updated |
| Environment | practice | testing |
| Filename | day52-practice.txt | day52-updated-testing.txt |
| Content | Hello from Terraform variables and outputs! | Day 52: Updated Terraform configuration successfully! |

### What Did We Learn?

When we changed the variable values, Terraform recalculated the local filename and the desired file content.

Terraform compared the desired configuration with the existing state and proposed the changes required to reach the new configuration.

This demonstrates why variables and locals make Terraform configurations reusable and flexible.

---

## 12. Troubleshooting Guide

### Problem 1 — Terraform Command Not Found

**Error:**

```text
terraform: command not found
```

**Possible cause:**

Terraform is not installed or its executable is not available through PATH.

**Solution:**

Check:

```bash
terraform version
```

If the command is unavailable, verify the installation and PATH.

### Problem 2 — Provider Download Failed

**Possible error:**

```text
Error: Failed to install provider
```

**Possible causes:**

- Internet connection problems.
- Incorrect provider source.
- Invalid provider version.
- Terraform Registry access problems.

**Solution:**

Verify the provider declaration:

```hcl
local = {
  source  = "hashicorp/local"
  version = "~> 2.5"
}
```

Then retry:

```bash
terraform init
```

### Problem 3 — Invalid Variable Value

**Possible cause:**

A variable receives a value that does not match its declared type or validation rule.

**Solution:**

Check the variable declaration and the value supplied in `terraform.tfvars`.

For example, a string should be written with quotation marks:

```hcl
environment = "testing"
```

### Problem 4 — Variable Not Declared

**Possible error:**

```text
Reference to undeclared input variable
```

**Possible cause:**

The variable name is incorrect or its declaration is missing.

**Solution:**

Check `variables.tf` and verify the reference:

```hcl
var.project_name
```

Variable names must match exactly.

### Problem 5 — Incorrect Local Value Reference

**Possible cause:**

The local name is misspelled or referenced incorrectly.

Correct syntax:

```hcl
local.output_filename
```

Input variable syntax:

```hcl
var.project_name
```

Remember that `var` references variables and `local` references local values.

### Problem 6 — Generated File Has an Unexpected Name

**Possible cause:**

Incorrect input values or an incorrect local expression.

**Solution:**

Inspect:

```bash
cat terraform.tfvars
```

Check `locals.tf`:

```hcl
locals {
  output_filename = "${var.project_name}-${var.environment}.txt"
}
```

Then run:

```bash
terraform plan
```

Review the proposed filename.

### Problem 7 — Terraform Plan Shows Unexpected Changes

**Solution:**

Do not apply immediately.

Run:

```bash
terraform plan
```

Inspect the resource actions and compare the desired values with the existing configuration and state.

Only apply changes you understand and approve.

### Problem 8 — File Already Exists

**Possible cause:**

A file with the requested name already exists.

**Solution:**

Check the file and Terraform state before taking action.

Do not manually delete files that Terraform is managing as a quick fix. Investigate the resource state and the proposed plan first.

---

## 13. Day 52 Cleanup — Destroy Local Resources

### Objective

Remove the Terraform-managed local file created during this lab.

Make sure you are inside the Day 52 project directory:

```bash
cd ~/DevOps-Winter-Arc/day52-terraform-inputs
```

### Step 1 — Review the Destroy Plan

```bash
terraform plan -destroy
```

The plan should refer to the resource created in this lab:

```text
local_file.demo
```

### Step 2 — Destroy the Resource

```bash
terraform destroy
```

Review the plan and type:

```text
yes
```

Only if the plan refers exclusively to the Day 52 local file resource.

Terraform removes the managed local file and updates its state.

### Step 3 — Verify Cleanup

```bash
ls -la
```

Check the state:

```bash
terraform state list
```

There should be no remaining managed resources from this lab.

**Important:** This lab uses only the Local Provider. No AWS infrastructure or cloud billing is involved.

Do not delete Terraform state files manually as a substitute for `terraform destroy`.

---

## 14. Important Interview Questions and Answers

### Q1. What is an input variable in Terraform?

An input variable is a value supplied to Terraform configuration from an external source. It makes the configuration reusable and flexible.

### Q2. Why do we use variables in Terraform?

Variables prevent hardcoding values and allow the same Terraform configuration to be reused with different inputs.

### Q3. What are Terraform type constraints?

Type constraints define the kind of value a variable accepts, such as string, number, bool, list, map, set, or object.

### Q4. What is variable validation?

Variable validation allows us to define conditions that input values must satisfy. Invalid values cause Terraform to report an error.

### Q5. How can we pass variable values to Terraform?

Common methods include:

- Default values in variable blocks.
- `terraform.tfvars`.
- Custom `.tfvars` files.
- Environment variables using `TF_VAR_`.
- CLI flags such as `-var` and `-var-file`.

### Q6. What is variable precedence?

Variable precedence determines which value Terraform uses when the same variable is supplied from multiple sources. Higher-precedence sources override lower-precedence ones.

### Q7. What does sensitive = true do?

It marks a variable or output as sensitive so Terraform hides its value in many normal CLI displays.

It does not automatically encrypt or remove the value from state.

### Q8. What is the difference between a variable and a local?

A variable accepts input from outside the configuration, while a local stores a reusable value or calculated expression inside the configuration.

### Q9. What is a Terraform output?

An output exposes useful information from Terraform configuration, such as a file path, resource identifier, or computed value.

### Q10. What is a Terraform data source?

A data source reads information about an existing object without managing that object's lifecycle like a resource.

### Q11. What is the difference between a resource and a data source?

A resource creates and manages an object. A data source reads information about an existing object.

### Q12. What is terraform.tfvars?

It is a variable-values file that Terraform automatically loads to supply input variable values.

### Q13. What is the purpose of locals.tf?

It stores local values and expressions that can be reused within Terraform configuration.

### Q14. Why should we not commit secret tfvars files to GitHub?

They may contain passwords, tokens, API keys, or other sensitive values that should not be publicly exposed.

### Q15. Why should Terraform state be protected?

State can contain sensitive infrastructure information and values. It should be stored securely and never published publicly.

---

## 15. Day 52 Submission Requirements

The Day 52 PDF asks for these deliverables:

1. Submit all Terraform configuration files.
2. Attach outputs of `terraform init`, `terraform validate`, `terraform plan`, and `terraform apply`.
3. Show the generated text file and `terraform output`.
4. Demonstrate the result after changing at least two variable values.
5. Explain:
   - Resource vs data source.
   - Variable vs local.
   - Input vs output.

### Evidence to Capture

Recommended terminal evidence:

- Project folder showing all six configuration files.
- Successful `terraform init`.
- Successful `terraform fmt -recursive` and `terraform validate`.
- Initial plan showing one resource to add.
- Successful apply and generated file.
- Terraform output values.
- Updated `terraform.tfvars` values.
- Second plan and apply after changing variables.
- Updated generated filename and content.

---

## 16. Final Learning Summary

In Day 52, we learned how to make Terraform configurations reusable using input variables, local values, output values, and data sources.

We separated the Terraform project into multiple configuration files and used `terraform.tfvars` to provide input values.

We created a local text file using the Local Provider, changed variable values, generated a new Terraform plan, and applied the updated configuration.

We also learned the differences between:

- Variables and locals.
- Inputs and outputs.
- Resources and data sources.
- Normal and sensitive values.

### Important Commands Practised

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
terraform state list
terraform state show local_file.demo
terraform plan -destroy
terraform destroy
```

### Key Takeaways

- Input variables make Terraform configurations reusable.
- Type constraints define acceptable input types.
- Validation rules help reject invalid values.
- `terraform.tfvars` supplies variable values.
- Variable precedence determines which supplied value is used.
- Sensitive values should be protected even when marked sensitive.
- Locals store reusable expressions and calculated values.
- Outputs display useful information from Terraform.
- Data sources read information about existing objects.
- Resources manage the lifecycle of infrastructure objects.
- Always review Terraform plans before applying changes.

**Day 52 objective:** Build reusable Terraform configurations using variables, locals, outputs, and data sources while managing a local resource without creating billable cloud infrastructure.
