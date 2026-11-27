# Day 53 — Terraform Modules

**Topic:** Reusable Infrastructure as Code  
**Goal:** Build a reusable Terraform child module, call it from a root module, pass input variables, and read module outputs.

> This lab creates local files only. It does not create AWS resources or incur cloud charges.

## 1. What is a Terraform module?

A Terraform module is a collection of Terraform configuration files grouped together for a specific purpose. Modules help organize configuration and reuse the same infrastructure logic with different input values.

Every Terraform configuration has a **root module**. A root module can call other modules, which are called **child modules**.

### Root module vs. child module

| Term | Meaning in this lab |
|---|---|
| Root module | The Terraform configuration in the main project directory. It calls the child module. |
| Child module | The reusable configuration inside `modules/text_file/`. It creates a local file. |
| `source` | Tells Terraform where to find the child module. |
| Input variables | Values passed from the root module into the child module. |
| Outputs | Values returned by a module for another module or the user to consume. |

### Module workflow

```text
Root module
  |
  | calls module using source
  | passes filename and content
  v
Child module: modules/text_file/
  |
  | uses its input variables
  v
local_file resource creates a file
  |
  | returns file_path output
  v
Root module reads module.report_file.file_path
  |
  v
terraform output displays the root output
```

## 2. Project setup

Use the Day 53 project directory:

```bash
cd ~/DevOps-Winter-Arc/Week8-Terraform/day53-Terraform-Modules
```

Create the child module directory:

```bash
mkdir -p modules/text_file
```

The final project structure should look like this:

```text
day53-Terraform-Modules/
├── main.tf
├── outputs.tf
└── modules/
    └── text_file/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## 3. Build the child module

The child module accepts a filename and content, creates a local file, and returns its path.

### `modules/text_file/variables.tf`

```hcl
variable "filename" {
  type = string
}

variable "content" {
  type = string
}
```

**Explanation:**
- `filename` is the path and name of the file to create.
- `content` is the text to write into the file.
- `type = string` means Terraform expects a text value for each variable.

### `modules/text_file/main.tf`

```hcl
resource "local_file" "this" {
  filename = var.filename
  content  = var.content
}
```

**Explanation:**
- `local_file` is a resource from the `hashicorp/local` provider.
- `this` is the local name assigned to this resource inside the module.
- `var.filename` and `var.content` refer to the child module's input variables.

### `modules/text_file/outputs.tf`

```hcl
output "file_path" {
  value = local_file.this.filename
}
```

**Explanation:** This output returns the filename configured for the resource. The root module can access it through the module call.

## 4. Build the root module

### Root `main.tf`

Create or edit `main.tf` in the project root—not inside `modules/text_file/`.

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

module "report_file" {
  source   = "./modules/text_file"
  filename = "${path.module}/report.txt"
  content  = "Created by a reusable Terraform module."
}
```

**Explanation:**
- The `terraform` block declares the local provider and its version constraint.
- `module "report_file"` calls the child module and gives this particular call the name `report_file`.
- `source = "./modules/text_file"` points to the child module's folder.
- `filename` and `content` are input values passed to the child module.
- `${path.module}` refers to the directory of the module where the expression is used—in this case, the root module directory.

### Root `outputs.tf`

```hcl
output "generated_file" {
  value = module.report_file.file_path
}
```

**Explanation:** `module.report_file.file_path` reads the `file_path` output from the child module call named `report_file`.

## 5. Initialize, validate, plan, and apply

Run these commands from the **project root**:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Review the plan before applying. Then run:

```bash
terraform apply
```

When Terraform asks for confirmation, type `yes` only after reviewing the plan.

Check the output and generated file:

```bash
terraform output
cat report.txt
```

Expected file content:

```text
Created by a reusable Terraform module.
```

## 6. Change a module input

Open the **root** `main.tf`:

```bash
nano main.tf
```

Change the `content` value in the `report_file` module call, for example:

```hcl
content = "Day 53: I changed the module input."
```

Save the file, then run:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
cat report.txt
```

After confirming the plan and applying, the file should contain the new message. This demonstrates that the root module controls the child module's behavior through its inputs.

## 7. Reusability challenge

### Challenge A — Call the same child module a second time

Add a second module block to the root `main.tf`:

```hcl
module "test_file" {
  source   = "./modules/text_file"
  filename = "${path.module}/test.txt"
  content  = "This is the second module call."
}
```

Both module calls use the same child module but pass different filenames and content.

### Challenge B — Add an environment input

Add this variable to `modules/text_file/variables.tf`:

```hcl
variable "environment" {
  type = string
}
```

Update `modules/text_file/main.tf` so the environment is included in the file content:

```hcl
resource "local_file" "this" {
  filename = var.filename
  content  = "${var.environment}: ${var.content}"
}
```

Pass an `environment` value in **each** root module call. For example:

```hcl
environment = "development"
```

Use a different value in the second call, such as `"testing"`.

### Challenge C — Add another child output and expose it

Add this output to `modules/text_file/outputs.tf`:

```hcl
output "file_content" {
  value = local_file.this.content
}
```

Expose the first module call's output in the root `outputs.tf`:

```hcl
output "generated_file_content" {
  value = module.report_file.file_content
}
```

### Challenge D — Verify both module calls

After making the challenge changes, run:

```bash
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Review the plan before confirming the apply. Then check:

```bash
cat report.txt
cat test.txt
terraform output
```

Verify that both files contain the expected, different messages and that the root outputs are available.

### Challenge E — Explain module reuse

Write a short explanation of how another Terraform project could use this child module. Mention that a local module can be referenced with a path such as `./modules/text_file`, and that the calling module must provide the required inputs.

## 8. Terraform Registry

The Terraform Registry is a public directory of Terraform providers and modules. For the submission:

1. Find one public module in the Terraform Registry.
2. Record its name.
3. Describe what it is intended to help configure or create.

The lab asks you to find and describe a public module; it does not require using a Registry module in this local-file exercise.

## 9. Troubleshooting

### Terraform says a required module argument is missing

Check that every required child-module input is set in each root module call. After adding `environment`, for example, both calls need an `environment` value.

### Terraform cannot find the child module

Run Terraform from the project root and check that the path exists:

```bash
ls modules/text_file
```

The root module's source should be:

```hcl
source = "./modules/text_file"
```

### Terraform says an output does not exist

Check that the output is declared in the child module's `outputs.tf` and that the root output references the correct module call and output name.

### The file content is not what I expected

Check the `content` input in the root module call and the expression used for `content` in the child module's resource. Then run `terraform plan` and inspect the proposed change before applying.

### Formatting or validation fails

Run:

```bash
terraform fmt -recursive
terraform validate
```

Read the exact error message and check the file and line it identifies.

## 10. Interview questions

1. What is a Terraform module?
2. What is the difference between a root module and a child module?
3. How do you call a local module?
4. How are variables passed into a module?
5. How does the root module access a child module's output?
6. Why are clear module inputs and outputs important?
7. What is the Terraform Registry?

## 11. Cleanup

When you have finished the lab and no longer need the generated files, run:

```bash
terraform destroy
```

Review the destroy plan and confirm only the lab's local resources are being removed. Type `yes` when prompted, then verify that the generated files have been removed.

**Important:** Do not hardcode credentials or secrets in modules. Do not commit Terraform state or secret variable files to GitHub.

---

**Day 53 takeaway:** A root module can reuse a child module by passing inputs, while child outputs allow useful values to be returned and consumed by the root module.
