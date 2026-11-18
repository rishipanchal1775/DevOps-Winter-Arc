# DEVOPS WINTER ARC — DAY 48
## Kubernetes Production: RBAC & Security

**Day:** 48 / 90  
**Platform:** Kubernetes  
**Environment:** WSL2 Ubuntu + Minikube  
**Cluster:** Minikube  
**Kubernetes Version:** v1.37.0  
**Namespace:** `day48-lab`  
**Focus:** RBAC · Role · ClusterRole · RoleBinding · ClusterRoleBinding · ServiceAccounts · Least Privilege

---

# 1. Today's Mission

Learn how Kubernetes controls who can access cluster resources and what actions they are allowed to perform.

In Kubernetes, not every user or application should have administrative access to the cluster.

For example, an application that only needs to view Pods should not receive permission to delete Pods, read Secrets or modify cluster resources.

Kubernetes uses Role-Based Access Control (RBAC) to manage these permissions.

Today's practical lab creates a dedicated read-only identity called `pod-viewer` and tests its permissions.

### Learning Objectives

- Understand authentication, authorization and admission control.
- Explain Role, ClusterRole, RoleBinding and ClusterRoleBinding.
- Understand ServiceAccounts and least privilege.
- Create namespace-scoped read-only access.
- Test allowed and denied Kubernetes API actions.
- Inspect existing cluster security resources.
- Identify the ServiceAccount used by an existing workload.
- Troubleshoot common RBAC permission problems.

---

# 2. Key Concepts

## 2.1 Authentication

Authentication identifies who is making a request to the Kubernetes API.

It answers:

**Who are you?**

Examples:
- A Kubernetes user.
- A ServiceAccount.
- An identity authenticated through an external identity provider.

## 2.2 Authorization

Authorization decides whether the authenticated identity is allowed to perform a particular action.

It answers:

**What are you allowed to do?**

For example:

- Can this identity list Pods?
- Can it delete a Deployment?
- Can it read Secrets?

Kubernetes RBAC is one of the mechanisms used for authorization.

## 2.3 Admission Control

Admission control checks or modifies API requests before the requested objects are stored.

It can validate or modify incoming Kubernetes resources.

Remember:

| Security concept | Purpose |
|---|---|
| Authentication | Identifies the requester |
| Authorization | Checks the requester's permissions |
| Admission control | Checks or modifies API requests before storage |

Simple explanation:

- Authentication = Identity.
- Authorization = Permission.
- Admission control = Request validation or modification.

## 2.4 What is RBAC?

RBAC stands for Role-Based Access Control.

It is a Kubernetes authorization mechanism that controls which identities can perform which actions on Kubernetes resources.

RBAC permissions specify three important things:

1. API groups
2. Resources
3. Verbs

Example:

```yaml
apiGroups: [""]
resources: ["pods"]
verbs: ["get", "list", "watch"]
```

Explanation:

- `apiGroups: [""]` means the core Kubernetes API group.
- `resources: ["pods"]` means the permissions apply to Pods.
- `verbs` specifies the allowed operations.

The identity can get, list and watch Pods, but this rule does not grant permission to delete Pods.

## 2.5 Role

A Role defines permissions within a particular namespace.

For example, a Role can allow an identity to view Pods in `day48-lab` without granting those permissions in the `default` namespace.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: day48-lab
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

Important:

- A Role is namespace-scoped.
- It defines which resources can be accessed.
- It defines which actions are allowed.

## 2.6 ClusterRole

A ClusterRole defines permissions that can be used at the cluster level or reused through bindings.

It can define access to:

- Cluster-scoped resources.
- Namespaced resources across namespaces when granted using a ClusterRoleBinding.
- Namespaced resources within one namespace when referenced by a RoleBinding.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pod-viewer-cluster
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

Unlike a Role, a ClusterRole does not belong to one namespace.

## 2.7 RoleBinding

A RoleBinding grants the permissions defined by a Role or ClusterRole within a particular namespace.

It connects an identity to the required permissions.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: day48-lab
subjects:
  - kind: ServiceAccount
    name: pod-viewer
    namespace: day48-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

Here:

- Subject = `pod-viewer` ServiceAccount.
- Role = `pod-reader`.
- Binding = `pod-reader-binding`.

The RoleBinding connects the ServiceAccount to the Role.

Important: A RoleBinding that references a ClusterRole grants its permissions only within the RoleBinding's namespace.

## 2.8 ClusterRoleBinding

A ClusterRoleBinding grants the permissions defined by a ClusterRole across the cluster.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-pod-reader-binding
subjects:
  - kind: ServiceAccount
    name: pod-viewer
    namespace: day48-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-viewer-cluster
```

Important:

- A ClusterRoleBinding references a ClusterRole.
- It grants those permissions across the cluster.
- Use it carefully because it can provide much broader access than a RoleBinding.

Do not create a ClusterRoleBinding for this practical lab.

## 2.9 ServiceAccount

A ServiceAccount is an identity used by a Pod or workload when it communicates with the Kubernetes API.

Instead of giving every application administrator privileges, we can create a dedicated ServiceAccount and grant only the permissions required.

Example:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-viewer
  namespace: day48-lab
```

This creates a ServiceAccount named `pod-viewer`.

A Pod can use it through:

```yaml
spec:
  serviceAccountName: pod-viewer
```

## 2.10 RBAC Verbs

RBAC rules use verbs to specify which actions are allowed.

| Verb | Meaning |
|---|---|
| get | Read an individual resource |
| list | List resources |
| watch | Watch resource changes |
| create | Create resources |
| update | Update resources |
| patch | Partially modify resources |
| delete | Delete resources |

Today's lab grants only:

```text
get
list
watch
```

## 2.11 Principle of Least Privilege

Least privilege means giving a user or workload only the minimum permissions needed to perform its task.

Example:

Suppose an application only needs to view Pods.

It should receive:

```yaml
verbs: ["get", "list", "watch"]
```

It should not receive unnecessary permissions such as:

```yaml
verbs: ["*"]
```

Avoid wildcard permissions and broad `cluster-admin` access for application workloads.

**Important:** Kubernetes RBAC permissions are additive. A RoleBinding does not create a deny rule. Another RoleBinding or ClusterRoleBinding may grant additional permissions.

---

# 3. Understand How RBAC Components Work Together

The most important relationship in today's lab is between:

- ServiceAccount
- Role
- RoleBinding

### RBAC Architecture

```text
                KUBERNETES API
                       |
                       |
                 AUTHENTICATION
                       |
                       v
                 ServiceAccount
                    pod-viewer
                       |
                       |
                       v
                  RoleBinding
               pod-reader-binding
                       |
                       |
                       v
                     Role
                  pod-reader
                       |
                       |
              Permissions Granted
                       |
              -------------------
              |        |        |
             get      list    watch
              |        |        |
              -------------------
                       |
                       v
                    PODS
                 day48-lab
```

### How the process works

**Step 1 — Identity**

The ServiceAccount `pod-viewer` represents the identity making requests to the Kubernetes API.

**Step 2 — Permission definition**

The Role `pod-reader` defines which operations the identity is allowed to perform.

**Step 3 — Binding**

The RoleBinding connects the ServiceAccount to the Role.

**Step 4 — Authorization**

When the identity requests to list Pods, Kubernetes checks whether an applicable RBAC rule grants that permission.

**Step 5 — Access decision**

- Listing Pods in `day48-lab` is allowed.
- Getting Pods in `day48-lab` is allowed.
- Deleting Pods is not granted.
- Listing Secrets is not granted.
- Listing Pods in `default` is not granted by this RoleBinding.

Other applicable bindings can add permissions, so these expected results assume no additional grants.

---

# 4. Practical Lab A — Create a Read-Only Identity

## Step 1 — Check the Kubernetes environment

Verify the current context:

```bash
kubectl config current-context
```

Expected:

```text
minikube
```

Check the current namespace:

```bash
kubectl config view --minify | grep namespace
```

If the namespace is not `default`, reset it:

```bash
kubectl config set-context --current --namespace=default
```

Check Minikube:

```bash
minikube status
```

Check Kubernetes nodes:

```bash
kubectl get nodes
```

Expected:

```text
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   ...   v1.37.0
```

## Step 2 — Create the working directory

```bash
cd ~/DevOps-Winter-Arc/Week7-Kubernetes-Production
```

Create the Day 48 folder:

```bash
mkdir -p day48-Kubernetes-RBAC-Security
```

Enter the directory:

```bash
cd day48-Kubernetes-RBAC-Security
```

Verify:

```bash
pwd
```

## Step 3 — Create the RBAC manifest

Create:

```bash
nano day48-rbac.yaml
```

Paste the following YAML:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: day48-lab
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-viewer
  namespace: day48-lab
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: day48-lab
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: day48-lab
subjects:
  - kind: ServiceAccount
    name: pod-viewer
    namespace: day48-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

Save and exit:

- Press `Ctrl + O`.
- Press Enter.
- Press `Ctrl + X`.

### YAML Explanation

**Namespace**

```yaml
kind: Namespace
metadata:
  name: day48-lab
```

Creates a dedicated namespace for the lab.

**ServiceAccount**

```yaml
kind: ServiceAccount
metadata:
  name: pod-viewer
  namespace: day48-lab
```

Creates the identity `pod-viewer`.

**Role**

```yaml
kind: Role
metadata:
  name: pod-reader
  namespace: day48-lab
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

Grants read-only Pod permissions within `day48-lab`.

**RoleBinding**

```yaml
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: day48-lab
subjects:
  - kind: ServiceAccount
    name: pod-viewer
    namespace: day48-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

Connects the ServiceAccount to the Role.

Without the RoleBinding, creating the Role and ServiceAccount alone would not grant the ServiceAccount these permissions.

## Step 4 — Apply the manifest

```bash
kubectl apply -f day48-rbac.yaml
```

Expected:

```text
namespace/day48-lab created
serviceaccount/pod-viewer created
role.rbac.authorization.k8s.io/pod-reader created
rolebinding.rbac.authorization.k8s.io/pod-reader-binding created
```

## Step 5 — Inspect the created resources

Check Role and RoleBinding:

```bash
kubectl get role,rolebinding -n day48-lab
```

Check ServiceAccount:

```bash
kubectl get serviceaccount -n day48-lab
```

Inspect Role details:

```bash
kubectl describe role pod-reader -n day48-lab
```

Inspect RoleBinding details:

```bash
kubectl describe rolebinding pod-reader-binding -n day48-lab
```

Expected Role rules:

```text
Resources   Non-Resource URLs   Resource Names   Verbs
pods        []                  []               [get list watch]
```

This confirms that the Role grants only the required read permissions.

---

# 5. Practical Lab B — Test Permissions

The objective is to test whether the `pod-viewer` ServiceAccount can perform the allowed and denied actions.

We will use Kubernetes impersonation through the `--as` option.

The identity format is:

```text
system:serviceaccount:<namespace>:<serviceaccount-name>
```

For this lab:

```text
system:serviceaccount:day48-lab:pod-viewer
```

The administrative context must have permission to impersonate ServiceAccounts. On a local Minikube administrative context this is normally available.

## Step 1 — Test listing Pods

```bash
kubectl auth can-i list pods -n day48-lab --as=system:serviceaccount:day48-lab:pod-viewer
```

Expected:

```text
yes
```

Explanation:

The Role grants the `list` verb for Pods in `day48-lab`.

## Step 2 — Test getting Pods

```bash
kubectl auth can-i get pods -n day48-lab --as=system:serviceaccount:day48-lab:pod-viewer
```

Expected:

```text
yes
```

Explanation:

The Role grants the `get` verb for Pods.

## Step 3 — Test deleting Pods

```bash
kubectl auth can-i delete pods -n day48-lab --as=system:serviceaccount:day48-lab:pod-viewer
```

Expected:

```text
no
```

Explanation:

The Role does not include the `delete` verb.

The ServiceAccount can read Pod information but cannot delete Pods through this Role.

## Step 4 — Test listing Secrets

```bash
kubectl auth can-i list secrets -n day48-lab --as=system:serviceaccount:day48-lab:pod-viewer
```

Expected:

```text
no
```

Explanation:

The Role grants permissions only for Pods.

It does not grant access to Secrets.

This is important because Kubernetes Secrets can contain sensitive application information.

## Step 5 — Test listing Pods in another namespace

```bash
kubectl auth can-i list pods -n default --as=system:serviceaccount:day48-lab:pod-viewer
```

Expected:

```text
no
```

Explanation:

The RoleBinding exists only in `day48-lab`.

It does not grant Pod access in the `default` namespace.

## Expected permission results

| Permission test | Expected result |
|---|---|
| List Pods in day48-lab | yes |
| Get Pods in day48-lab | yes |
| Delete Pods in day48-lab | no |
| List Secrets in day48-lab | no |
| List Pods in default | no |

### Understanding the results

The first two commands should return `yes` because the Role explicitly grants `get` and `list`.

The remaining three commands should return `no` because the Role does not grant those actions or access to those resources in the other namespace.

If a result differs, investigate other RoleBindings and ClusterRoleBindings because RBAC permissions are additive.

---

# 6. Practical Lab C — Inspect Cluster Security

The objective is to understand the existing RBAC configuration and inspect the ServiceAccount used by an existing workload.

Do not modify existing shared cluster security resources.

## Step 1 — Inspect all Roles and RoleBindings

```bash
kubectl get roles,rolebindings -A
```

Explanation:

- `roles` displays namespace-scoped permission definitions.
- `rolebindings` displays namespace-scoped permission assignments.
- `-A` displays resources across all namespaces.

## Step 2 — Inspect ClusterRoles and ClusterRoleBindings

```bash
kubectl get clusterroles,clusterrolebindings
```

Explanation:

- ClusterRoles define cluster-level or reusable permissions.
- ClusterRoleBindings grant ClusterRole permissions across the cluster.

These resources may include Kubernetes system and Minikube components.

Do not modify them as part of this exercise.

## Step 3 — Inspect ServiceAccounts

```bash
kubectl get serviceaccounts -A
```

This lists ServiceAccounts across all namespaces.

Find:

```text
pod-viewer
```

in:

```text
day48-lab
```

## Step 4 — Identify an existing workload's ServiceAccount

First list Pods:

```bash
kubectl get pods -A
```

Choose one existing workload from a namespace other than `day48-lab`.

Inspect only its ServiceAccount name:

```bash
kubectl get pod -n <namespace> <pod-name> -o jsonpath='{.spec.serviceAccountName}'
```

Replace:

- `<namespace>` with the actual namespace.
- `<pod-name>` with the actual Pod name.

Example:

```bash
kubectl get pod -n default example-pod -o jsonpath='{.spec.serviceAccountName}'
```

If the Pod specification omits `serviceAccountName`, Kubernetes uses the namespace's `default` ServiceAccount.

**Security warning:** Do not copy, display or submit ServiceAccount tokens, Secrets, kubeconfigs or credential data. Only inspect the ServiceAccount name.

---

# 7. Security Best Practices — Least Privilege

Kubernetes security requires careful permission management.

Follow these recommendations:

## 7.1 Use Dedicated ServiceAccounts

Create a separate ServiceAccount for workloads that need Kubernetes API access.

Avoid using a highly privileged shared identity for every application.

## 7.2 Prefer Namespace-Scoped Roles

Use Roles and RoleBindings when an application only needs permissions inside one namespace.

Avoid cluster-wide access when it is not necessary.

## 7.3 Grant Only Required Permissions

Give workloads only the API resources and verbs they need.

For example:

```yaml
resources: ["pods"]
verbs: ["get", "list", "watch"]
```

Avoid unnecessary wildcard permissions.

## 7.4 Avoid cluster-admin for Application Workloads

The `cluster-admin` role grants extremely broad administrative access.

It should not be assigned to ordinary application workloads.

## 7.5 Protect Credentials

Never:

- Put credentials in source code.
- Publish Kubernetes Secrets in public repositories.
- Share kubeconfig files.
- Display or submit ServiceAccount tokens unnecessarily.

## 7.6 Review Unused Bindings

Regularly inspect Roles, RoleBindings, ClusterRoles and ClusterRoleBindings.

Remove unused permissions through an approved process.

## 7.7 Understand RBAC Limitations

RBAC protects Kubernetes API actions.

It does not replace:

- Container security.
- Network security.
- Cloud IAM.
- Operating-system security.
- Application-level authentication and authorization.

---

# 8. Troubleshooting Kubernetes RBAC

## Problem 1 — Forbidden Error

### Symptoms

You may see:

```text
Error from server (Forbidden):
pods is forbidden
```

### Possible causes

- Incorrect ServiceAccount identity.
- Wrong namespace.
- Missing RoleBinding.
- Incorrect Role reference.
- Required verb is missing.
- Another applicable permission or policy is involved.

### Troubleshooting commands

Check the ServiceAccount:

```bash
kubectl get serviceaccount pod-viewer -n day48-lab
```

Check the Role:

```bash
kubectl describe role pod-reader -n day48-lab
```

Check the RoleBinding:

```bash
kubectl describe rolebinding pod-reader-binding -n day48-lab
```

Test permission:

```bash
kubectl auth can-i list pods -n day48-lab --as=system:serviceaccount:day48-lab:pod-viewer
```

### Solution

Verify the identity, namespace, API group, resource, verb and RoleBinding subject.

Make sure the RoleBinding references the correct Role.

## Problem 2 — `kubectl auth can-i` Returns No

### Symptoms

A permission test unexpectedly returns:

```text
no
```

### Possible causes

- ServiceAccount does not exist.
- ServiceAccount name is incorrect.
- Namespace is incorrect.
- RoleBinding subject does not match.
- Role does not contain the required permission.

### Troubleshooting commands

```bash
kubectl get serviceaccount pod-viewer -n day48-lab
```

```bash
kubectl get role,rolebinding -n day48-lab
```

```bash
kubectl describe role pod-reader -n day48-lab
```

```bash
kubectl describe rolebinding pod-reader-binding -n day48-lab
```

### Solution

Check that the RoleBinding subject matches:

```yaml
subjects:
  - kind: ServiceAccount
    name: pod-viewer
    namespace: day48-lab
```

Also check the `roleRef`:

```yaml
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

## Problem 3 — YAML Rejected

### Symptoms

Applying the YAML may produce errors such as:

```text
error: unable to recognize ...
```

or:

```text
error: error validating data
```

### Possible causes

- Incorrect API version.
- Incorrect indentation.
- Missing required fields.
- Incorrect resource name.
- Incorrect RoleBinding configuration.

### Troubleshooting commands

Display the file:

```bash
cat day48-rbac.yaml
```

Validate using a client-side dry run:

```bash
kubectl apply --dry-run=client -f day48-rbac.yaml
```

Check supported API resources:

```bash
kubectl api-resources
```

### Solution

Check:

- Namespace name.
- ServiceAccount name.
- Role name.
- RoleBinding subject.
- `roleRef` fields.
- YAML indentation.

## Problem 4 — Permission Is Unexpectedly Allowed

### Symptoms

A command that was expected to return:

```text
no
```

returns:

```text
yes
```

### Explanation

Kubernetes RBAC permissions are additive.

Another RoleBinding or ClusterRoleBinding may grant the permission.

A RoleBinding does not deny permissions granted by another binding.

### Troubleshooting commands

Inspect RoleBindings:

```bash
kubectl get rolebindings -A
```

Inspect ClusterRoleBindings:

```bash
kubectl get clusterrolebindings
```

Inspect Roles:

```bash
kubectl get roles -A
```

Inspect ClusterRoles:

```bash
kubectl get clusterroles
```

### Solution

Identify which existing binding grants the additional permission.

Do not try to create a deny rule. Kubernetes RBAC does not support explicit deny rules.

Do not remove shared permissions without authorization.

## Problem 5 — Unexpected ServiceAccount

### Symptoms

A workload appears to use a different ServiceAccount than expected.

### Possible causes

- `serviceAccountName` is not specified.
- The Pod uses the namespace's default ServiceAccount.
- The workload specification explicitly selects another ServiceAccount.

### Troubleshooting commands

Inspect only the ServiceAccount name:

```bash
kubectl get pod -n <namespace> <pod-name> -o jsonpath='{.spec.serviceAccountName}'
```

Inspect the namespace's ServiceAccounts:

```bash
kubectl get serviceaccounts -n <namespace>
```

### Solution

If the workload requires a dedicated identity, specify the appropriate ServiceAccount in its Pod template:

```yaml
spec:
  serviceAccountName: pod-viewer
```

For Deployments, this field belongs under:

```yaml
spec:
  template:
    spec:
      serviceAccountName: pod-viewer
```

Ensure that the ServiceAccount exists in the same namespace as the Pod.

---

# 9. Useful Kubernetes RBAC Commands

| Command | Purpose |
|---|---|
| `kubectl get roles -A` | List Roles across namespaces |
| `kubectl get rolebindings -A` | List RoleBindings across namespaces |
| `kubectl get clusterroles` | List ClusterRoles |
| `kubectl get clusterrolebindings` | List ClusterRoleBindings |
| `kubectl get serviceaccounts -A` | List ServiceAccounts |
| `kubectl describe role pod-reader -n day48-lab` | Inspect Role permissions |
| `kubectl describe rolebinding pod-reader-binding -n day48-lab` | Inspect RoleBinding |
| `kubectl auth can-i list pods -n day48-lab` | Check current identity's permission |
| `kubectl auth can-i list pods -n day48-lab --as=system:serviceaccount:day48-lab:pod-viewer` | Test ServiceAccount permission |
| `kubectl get pods -A` | List Pods across namespaces |
| `kubectl api-resources` | List Kubernetes API resources |

---

# 10. Interview Questions and Answers

## Q1. What is Kubernetes RBAC?

**Answer:**

RBAC stands for Role-Based Access Control.

It is a Kubernetes authorization mechanism that controls which identities can perform which actions on cluster resources.

It uses Roles, ClusterRoles, RoleBindings and ClusterRoleBindings to manage permissions.

## Q2. What is the difference between Role and ClusterRole?

**Answer:**

A Role defines permissions within a particular namespace.

A ClusterRole defines cluster-scoped permissions or reusable permission rules.

A Role is useful when an application only needs access to resources within one namespace.

A ClusterRole can be used for broader access when required.

## Q3. What is the difference between RoleBinding and ClusterRoleBinding?

**Answer:**

A RoleBinding grants permissions within a particular namespace.

It can reference either a Role or a ClusterRole.

A ClusterRoleBinding grants the permissions defined by a ClusterRole across the cluster.

## Q4. What is a ServiceAccount?

**Answer:**

A ServiceAccount is an identity used by a Pod or workload when it communicates with the Kubernetes API.

It allows workloads to authenticate to Kubernetes using a dedicated identity.

Permissions can then be granted to that identity through RBAC.

## Q5. Explain least privilege.

**Answer:**

Least privilege means giving a user or application only the minimum permissions required to perform its tasks.

For example, an application that only needs to view Pods should receive `get`, `list` and `watch` permissions instead of full administrative access.

## Q6. Name common RBAC verbs.

**Answer:**

Common Kubernetes RBAC verbs include:

- `get`
- `list`
- `watch`
- `create`
- `update`
- `patch`
- `delete`

They define which operations an identity is allowed to perform.

## Q7. Does Kubernetes RBAC support explicit deny rules?

**Answer:**

No.

Kubernetes RBAC permissions are additive.

If any applicable RoleBinding or ClusterRoleBinding grants the required permission, the request can be authorized.

A RoleBinding cannot explicitly deny permission granted by another binding.

---

# 11. Cleanup — Remove Day 48 Resources

After completing the practical lab, remove only the namespace created for Day 48.

### Step 1 — Inspect the lab resources

```bash
kubectl get all -n day48-lab
```

Inspect RBAC resources:

```bash
kubectl get role,rolebinding -n day48-lab
```

Inspect ServiceAccounts:

```bash
kubectl get serviceaccount -n day48-lab
```

### Step 2 — Delete the Day 48 namespace

```bash
kubectl delete namespace day48-lab
```

Expected:

```text
namespace "day48-lab" deleted
```

Deleting the namespace removes the lab's namespaced resources, including:

- ServiceAccount `pod-viewer`.
- Role `pod-reader`.
- RoleBinding `pod-reader-binding`.

### Step 3 — Verify namespace deletion

```bash
kubectl get namespaces
```

Confirm that `day48-lab` is no longer present.

### Step 4 — Restore the default namespace

```bash
kubectl config set-context --current --namespace=default
```

Verify:

```bash
kubectl config view --minify | grep namespace
```

Expected:

```text
namespace: default
```

### Important Cleanup Rules

- Delete only `day48-lab`.
- Do not delete other lab namespaces.
- Do not delete shared ClusterRoles.
- Do not delete shared ClusterRoleBindings.
- Do not disable Metrics Server.
- Do not modify existing Minikube system permissions.
- Never grant `cluster-admin` for this exercise.

No new AWS resources are required for this lab.

---

# 12. Key Takeaways

1. Authentication identifies who is making a Kubernetes API request.
2. Authorization decides whether the requester can perform an action.
3. Admission control checks or modifies API requests before objects are stored.
4. RBAC controls access to Kubernetes resources.
5. Role defines namespace-scoped permissions.
6. ClusterRole defines cluster-scoped or reusable permission rules.
7. RoleBinding grants permissions within a namespace.
8. ClusterRoleBinding grants ClusterRole permissions across the cluster.
9. ServiceAccounts provide identities for Pods and workloads.
10. Least privilege reduces unnecessary access and security risks.
11. RBAC permissions are additive; Kubernetes RBAC does not support explicit deny rules.
12. Always inspect existing permissions before modifying cluster security.

### Architecture to Remember

```text
                KUBERNETES API
                       |
                       v
                 AUTHENTICATION
                       |
                       v
                 ServiceAccount
                   pod-viewer
                       |
                       v
                  RoleBinding
               pod-reader-binding
                       |
                       v
                     Role
                  pod-reader
                       |
                       v
               Allowed Permissions
                 get / list / watch
                       |
                       v
                    PODS
                 day48-lab
```

**Day 48 Complete — Kubernetes RBAC & Security**

You now understand how Kubernetes controls API access through RBAC, how ServiceAccounts provide workload identities, and how to implement namespace-scoped read-only permissions using the principle of least privilege.
