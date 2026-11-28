# Day 57 — Terraform Functions & Expressions

## Overview

**Objective:** Practise Terraform built-in functions, expressions, conditionals, `for` expressions, `count`, `for_each`, dynamic blocks, and `terraform console`.

This lab uses the Terraform **local provider** to generate text files. It does not create AWS resources or incur cloud charges.

## Lab location

```text
~/DevOps-Winter-Arc/Week8-Terraform/day57-terraform-expressions/
```

## 1. Topics covered

- Expressions and string interpolation
- Built-in functions: `length`, `upper`, `lower`, `join`, `split`, `replace`, `format`, `lookup`, and `file`
- Conditional expressions and comparison operators
- `for` expressions with lists and maps
- `count` versus `for_each`
- Dynamic blocks and their use cases
- `try` and `coalesce` for optional values
- Testing expressions with `terraform console`

## 2. Create the lab directory

```bash
cd ~/DevOps-Winter-Arc/Week8-Terraform
mkdir -p day57-terraform-expressions
cd day57-terraform-expressions
```

Confirm the current directory:

```bash
pwd
```

## 3. Terraform configuration

Create `main.tf`:

```bash
nano main.tf
```

Add the following configuration:

```hcl
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
    test = "Testing environment"
    prod = "Production environment"
  }
}

resource "local_file" "environment" {
  for_each = var.environments

  filename = "${path.module}/${each.key}.txt"
  content  = "${upper(each.key)}: ${each.value}"
}

locals {
  environment_count = length(var.environments)

  environment_names = [
    for name, description in var.environments : upper(name)
  ]

  production_label = var.environments["prod"] == "Production environment" ? "Production" : "Non-production"
}
```

Save and exit nano with **Ctrl+O**, **Enter**, then **Ctrl+X**.

### Configuration explanation

- `required_providers` tells Terraform which provider to use. The `local` provider manages local files.
- `variable "environments"` defines a map of environment names and descriptions.
- `for_each = var.environments` creates one resource instance for each map entry.
- `each.key` is the map key, such as `dev`, `test`, or `prod`.
- `each.value` is the corresponding description.
- `path.module` is the path of the directory containing this Terraform module.
- `upper(each.key)` converts the environment name to uppercase.
- The `locals` block defines reusable expressions. Locals do not create infrastructure or files by themselves.

## 4. Initialize, format, and validate

Initialize the working directory and download the provider:

```bash
terraform init
```

Format the Terraform configuration:

```bash
terraform fmt -recursive
```

Validate the configuration:

```bash
terraform validate
```

A successful validation reports:

```text
Success! The configuration is valid.
```

## 5. Terraform expressions and functions

An **expression** is a Terraform construct that produces a value. It can be a literal value, variable reference, function call, comparison, conditional, or a combination of these.

### String interpolation

Terraform uses `${...}` to insert an expression's value into a string:

```hcl
filename = "${path.module}/${each.key}.txt"
content  = "${upper(each.key)}: ${each.value}"
```

For example, when `each.key` is `dev`, the filename becomes `dev.txt`, and the content becomes:

```text
DEV: Development environment
```

### Built-in functions

| Function | Purpose | Example |
|---|---|---|
| `length(value)` | Returns the number of elements in a collection or the number of characters in a string. | `length(["dev", "test"])` returns `2`. |
| `upper(string)` | Converts text to uppercase. | `upper("dev")` returns `"DEV"`. |
| `lower(string)` | Converts text to lowercase. | `lower("PROD")` returns `"prod"`. |
| `join(separator, list)` | Combines list elements into one string, placing the separator between them. | `join(", ", ["dev", "test"])` returns `"dev, test"`. |
| `split(separator, string)` | Splits a string into a list using the separator. | `split(",", "dev,test")` returns `["dev", "test"]`. |
| `replace(string, search, replacement)` | Replaces matching text. | `replace("dev-env", "-", "_")` returns `"dev_env"`. |
| `format(spec, values...)` | Formats values into a string. | `format("Environment: %s", "dev")` returns `"Environment: dev"`. |
| `lookup(map, key, default)` | Retrieves a map value; returns the default if the key is absent. | `lookup({dev="small"}, "test", "medium")` returns `"medium"`. |
| `file(path)` | Reads the contents of an existing file. | `file("${path.module}/dev.txt")` reads `dev.txt`. |
| `try(expressions...)` | Evaluates expressions in order and returns the first one that does not produce an error. | `try(var.optional_value, "fallback")` returns the fallback if the variable reference errors. |
| `coalesce(values...)` | Returns the first argument that is not null or an empty string. | `coalesce("", "default")` returns `"default"`. |

`file()` reads a file that already exists. In this lab, use it to read a generated file only after Terraform has created that file.

## 6. Conditional expressions

A conditional expression chooses one of two values based on a condition:

```hcl
condition ? true_value : false_value
```

Example:

```hcl
var.environments["prod"] == "Production environment" ? "Production" : "Non-production"
```

If the condition is true, the result is `"Production"`. Otherwise, the result is `"Non-production"`.

Common comparison operators include:

| Operator | Meaning |
|---|---|
| `==` | Equal to |
| `!=` | Not equal to |
| `>` | Greater than |
| `<` | Less than |
| `>=` | Greater than or equal to |
| `<=` | Less than or equal to |

## 7. For expressions

A `for` expression iterates over a collection and produces a new list or map.

Example that returns uppercase environment names:

```hcl
[for name in ["dev", "test", "prod"] : upper(name)]
```

Result:

```hcl
["DEV", "TEST", "PROD"]
```

A `for` expression can also iterate over a map:

```hcl
[for name, description in var.environments : upper(name)]
```

This produces a list of uppercase map keys.

## 8. Practice with Terraform console

Start the console:

```bash
terraform console
```

Enter each expression separately:

```hcl
length(["dev", "test", "prod"])
```

Expected result:

```text
3
```

```hcl
upper("winter arc")
```

Expected result:

```text
"WINTER ARC"
```

```hcl
join(", ", ["dev", "test", "prod"])
```

Expected result:

```text
"dev, test, prod"
```

```hcl
[for name in ["dev", "test", "prod"] : upper(name)]
```

Expected result:

```hcl
[
  "DEV",
  "TEST",
  "PROD",
]
```

```hcl
lookup({dev="small", prod="large"}, "test", "medium")
```

Expected result:

```text
"medium"
```

Additional exercises:

```hcl
lower("TERRAFORM")
split(",", "dev,test,prod")
replace("dev-environment", "-", "_")
format("Environment: %s", "dev")
local.environment_count
local.environment_names
local.production_label
```

Exit the console:

```text
exit
```

## 9. Plan and apply the configuration

Create a plan:

```bash
terraform plan
```

The plan should propose three local file resources, one for each environment key.

Apply the configuration:

```bash
terraform apply
```

Review the proposed changes and enter `yes` when Terraform asks for confirmation.

## 10. Verify the generated files

List the directory:

```bash
ls -l
```

Read each file:

```bash
cat dev.txt
cat test.txt
cat prod.txt
```

Expected contents:

```text
DEV: Development environment
TEST: Testing environment
PROD: Production environment
```

Check the Terraform-managed resource instances:

```bash
terraform state list
```

The state should include one `local_file.environment` instance for each environment key.

## 11. Change the environment map and observe the plan

Edit `main.tf`:

```bash
nano main.tf
```

Replace the variable's `default` map with:

```hcl
default = {
  dev  = "Development environment"
  test = "Testing environment - updated"
  qa   = "Quality assurance environment"
}
```

Format and validate:

```bash
terraform fmt
terraform validate
```

Review the changes:

```bash
terraform plan
```

The plan should show:

- `test.txt` updated because its content changed.
- `qa.txt` created because `qa` is a new map key.
- `prod.txt` removed because `prod` is no longer in the map.

Apply the changes:

```bash
terraform apply
```

Enter `yes` when prompted, then verify the files:

```bash
ls -l
cat dev.txt
cat test.txt
cat qa.txt
```

Record which files were created, updated, and removed.

## 12. Dynamic blocks — concept and reference example

A **dynamic block** generates repeated nested blocks inside a resource from a collection. For example, a resource might need several nested ingress rules. A dynamic block can generate those nested blocks from a list or map.

The following is an **AWS reference example only**. Do not add it to the local-file lab or apply it:

```hcl
# Reference example only — do not apply.
# This illustrates a dynamic nested block in an AWS security group.

resource "aws_security_group" "example" {
  name = "example"

  dynamic "ingress" {
    for_each = var.ingress_rules

    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

In this example, `var.ingress_rules` is a collection of rule objects. The dynamic block generates one nested `ingress` block for each item in that collection.

### Dynamic block versus resource-level `for_each`

- **Resource-level `for_each`** creates multiple separate Terraform resource instances. In this lab, it creates one `local_file.environment` instance for each environment.
- **Dynamic block** generates repeated nested blocks inside one resource. In the example, it generates multiple `ingress` blocks inside one security-group resource.
- A dynamic block does not create separate Terraform resource instances.

## 13. `count` versus `for_each`

Both `count` and `for_each` can create multiple instances of a resource.

### `count`

`count` uses a number to determine how many instances to create. Instances are identified by numeric indices, such as `[0]`, `[1]`, and `[2]`.

```hcl
resource "local_file" "example" {
  count    = 3
  filename = "${path.module}/example-${count.index}.txt"
  content  = "Example ${count.index}"
}
```

This creates three instances. `count.index` provides each instance's numeric index.

### `for_each`

`for_each` uses a map or set to create instances. Map instances are identified by their keys.

```hcl
resource "local_file" "environment" {
  for_each = var.environments

  filename = "${path.module}/${each.key}.txt"
  content  = "${upper(each.key)}: ${each.value}"
}
```

This creates one instance per map entry. The instance keys are `dev`, `test`, and `prod`.

**Main difference:** `count` identifies instances by index, while `for_each` identifies them by meaningful keys or set values. `for_each` is often easier to manage when each instance has its own name or associated data.

## 14. Interview questions and answers

### 1. What is a Terraform expression?

A Terraform expression is a construct that produces a value. Expressions can use literal values, variables, resource attributes, function calls, operators, conditionals, and collection transformations. For example, `upper("dev")` is an expression that evaluates to `"DEV"`.

### 2. Name five Terraform built-in functions.

Five examples are:

- `length()` — returns the length of a string or collection.
- `upper()` — converts text to uppercase.
- `lower()` — converts text to lowercase.
- `join()` — combines list elements into a string using a separator.
- `lookup()` — retrieves a value from a map, or returns a supplied default when the key is absent.

Other functions in this lab include `split()`, `replace()`, `format()`, `file()`, `try()`, and `coalesce()`.

### 3. What is a conditional expression?

A conditional expression evaluates a condition and returns one value if it is true and another if it is false. Its form is:

```hcl
condition ? true_value : false_value
```

For example:

```hcl
var.environments["prod"] == "Production environment" ? "Production" : "Non-production"
```

The expression returns `"Production"` when the comparison is true; otherwise it returns `"Non-production"`.

### 4. What is a `for` expression?

A `for` expression iterates over a list, set, or map and transforms its elements into a new collection. For example:

```hcl
[for name in ["dev", "test", "prod"] : upper(name)]
```

It returns a list containing `"DEV"`, `"TEST"`, and `"PROD"`.

### 5. What is the difference between `count` and `for_each`?

`count` creates a specified number of resource instances and identifies them by numeric index. `for_each` creates instances from a map or set and identifies them by keys or values. Use `count` when instances are interchangeable and a number is sufficient; use `for_each` when instances have meaningful names or distinct associated values.

### 6. What is a dynamic block?

A dynamic block generates repeated nested blocks within a resource from a collection. It is useful when the number of nested configuration blocks depends on input data. For example, a dynamic block can generate multiple ingress rules inside a security-group resource.

### 7. How is a dynamic block different from resource-level `for_each`?

Resource-level `for_each` creates multiple separate Terraform resource instances. A dynamic block generates repeated nested blocks within one resource. The local-file lab uses resource-level `for_each` to create one file resource per environment; the security-group reference uses a dynamic block to generate multiple nested ingress rules within one resource.

### 8. What is `terraform console` used for?

`terraform console` is an interactive environment for evaluating Terraform expressions. It helps test function calls, variable values, conditionals, and `for` expressions before using them in a configuration. It is also useful for inspecting values from the current Terraform configuration and state.

## 15. Cleanup

After recording the generated file contents and the plan/apply results, destroy the lab resources:

```bash
terraform destroy
```

Review the proposed changes and enter `yes` when prompted. This removes the local files managed by Terraform.

The lab creates local text files only. Do not commit Terraform state files or secrets to GitHub.

## 16. Important notes

- This lab uses the `local` provider and does not require AWS credentials.
- The dynamic-block security-group example is for understanding the concept only; do not apply it.
- Save the generated file contents and command results before running `terraform destroy`.
- Terraform state files contain state information and should not be committed to GitHub.
