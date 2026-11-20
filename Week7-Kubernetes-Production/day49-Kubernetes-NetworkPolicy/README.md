# Day 49 — Kubernetes Production: NetworkPolicy

## Overview

Day 49 focuses on Kubernetes NetworkPolicy and how it controls communication between Pods.

In this lab, we create three Pods in a dedicated namespace, test their connectivity, apply a default-deny ingress policy, and then allow traffic only from selected client Pods.

**Environment:** Minikube / Kubernetes  
**Namespace:** `day49-lab`  
**Main topics:** NetworkPolicy, Ingress, Egress, Pod selectors, CNI support

---

## 1. Learning Objectives

By completing this lab, you should understand:

- What Kubernetes NetworkPolicy is and why it is used.
- The difference between ingress and egress traffic.
- How `podSelector` identifies Pods.
- How to create a default-deny ingress policy.
- How to allow traffic from specific Pods.
- Why a NetworkPolicy requires a compatible CNI plugin for enforcement.
- How egress restrictions can affect DNS and other outbound connections.

---

## 2. Important Concepts

### 2.1 What is NetworkPolicy?

A Kubernetes NetworkPolicy is an object that controls network communication for selected Pods.

It defines which incoming and outgoing connections are permitted.

NetworkPolicy is useful for improving application security by restricting unnecessary communication between workloads.

### 2.2 Ingress Traffic

Ingress means incoming traffic entering a Pod.

Example:

```text
Client Pod  ---- HTTP Request ---->  Web Pod
```

A NetworkPolicy can control which Pods are allowed to connect to the Web Pod.

### 2.3 Egress Traffic

Egress means outgoing traffic leaving a Pod.

Example:

```text
Application Pod  ---- Request ---->  External Service
```

A NetworkPolicy can restrict which destinations a Pod is allowed to reach.

### 2.4 Pod Selector

A `podSelector` identifies which Pods a NetworkPolicy applies to.

Example:

```yaml
podSelector:
  matchLabels:
    app: web
```

This policy selects Pods with the label `app: web` in the policy's namespace.

An empty selector:

```yaml
podSelector: {}
```

selects all Pods in the policy's namespace.

### 2.5 Default-Deny Ingress

A NetworkPolicy that selects Pods and declares ingress isolation without defining any ingress allow rules blocks incoming traffic to those selected Pods, subject to CNI enforcement.

Example:

```yaml
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
```

### 2.6 Additive Policy Behavior

Kubernetes NetworkPolicies are additive.

If multiple policies select a Pod, traffic is allowed when it matches at least one applicable allow rule.

A separate policy does not automatically override or cancel another policy.

### 2.7 CNI Plugin Support

A NetworkPolicy object can be created successfully even when the cluster's network implementation does not enforce it.

The cluster must use a CNI plugin that supports Kubernetes NetworkPolicy.

Always verify CNI support before relying on NetworkPolicy for security.

---

## 3. Lab Architecture

We create three Pods inside the `day49-lab` namespace.

```text
                  day49-lab namespace

        ┌──────────────────────────────┐
        │                              │
        │       client Pod             │
        │       app: client            │
        │                              │
        └──────────────┬───────────────┘
                       │
                       │ HTTP :80
                       ▼
                ┌──────────────┐
                │   web Pod    │
                │   app: web   │
                │   NGINX      │
                └──────────────┘
                       ▲
                       │
                  BLOCKED
                       │
                ┌──────────────┐
                │  other Pod   │
                │  app: other  │
                │              │
                └──────────────┘
```

After applying the policies:

- `client` is allowed to connect to `web` on TCP port 80.
- `other` is not allowed to connect to `web`.
- The policy applies only to the selected Web Pod in `day49-lab`.

---

## 4. Check the Kubernetes Environment

Before creating resources, verify the current cluster.

```bash
kubectl config current-context
kubectl get nodes -o wide
minikube status
```

Check the network components:

```bash
kubectl get pods -n kube-system -o wide
kubectl get daemonsets -A
minikube addons list
```

**Important:** Confirm that the installed CNI supports NetworkPolicy enforcement before running the connectivity tests. Do not install or replace a CNI in a shared cluster without reviewing the impact.

---

## 5. Create the Lab Workload

Create a file named `day49.yaml`.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: day49-lab

---
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: day49-lab
  labels:
    app: web
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80

---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: day49-lab
  labels:
    app: client
spec:
  containers:
    - name: curl
      image: curlimages/curl:8.10.1
      command: ["sh", "-c", "sleep 36000"]

---
apiVersion: v1
kind: Pod
metadata:
  name: other
  namespace: day49-lab
  labels:
    app: other
spec:
  containers:
    - name: curl
      image: curlimages/curl:8.10.1
      command: ["sh", "-c", "sleep 36000"]
```

Apply the manifest:

```bash
kubectl apply -f day49.yaml
```

Wait for all Pods to become Ready:

```bash
kubectl wait --for=condition=Ready pod --all -n day49-lab --timeout=120s
```

Check the Pods and labels:

```bash
kubectl get pods -n day49-lab --show-labels
```

Expected Pods:

```text
web
client
other
```

---

## 6. Lab A — Test Baseline Connectivity

First, test connectivity before applying any NetworkPolicy.

Get the Web Pod IP:

```bash
kubectl get pod web -n day49-lab -o wide
```

Copy the Web Pod IP from the output.

Test from the client Pod:

```bash
kubectl exec -n day49-lab client -- curl -m 5 http://WEB_POD_IP
```

Replace `WEB_POD_IP` with the actual IP address.

You should receive the NGINX welcome page if connectivity is working.

Also test from the other Pod:

```bash
kubectl exec -n day49-lab other -- curl -m 5 http://WEB_POD_IP
```

Record the baseline results.

**Why do this first?**

We need to understand whether communication works before applying a policy so we can compare the behavior afterward.

---

## 7. Lab B — Apply Default-Deny Ingress

Create a file named `deny-ingress.yaml`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-web-ingress
  namespace: day49-lab
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
```

Apply the policy:

```bash
kubectl apply -f deny-ingress.yaml
```

Verify the policy:

```bash
kubectl get networkpolicy -n day49-lab
```

Describe it:

```bash
kubectl describe networkpolicy deny-web-ingress -n day49-lab
```

Test connectivity again:

```bash
kubectl exec -n day49-lab client -- curl -m 5 http://WEB_POD_IP
```

**Expected behavior when the CNI enforces NetworkPolicy:** The request should fail or time out because no ingress sources have been allowed.

### What happened?

The policy selects the Web Pod using:

```yaml
matchLabels:
  app: web
```

It enables ingress isolation:

```yaml
policyTypes:
  - Ingress
```

There are no ingress allow rules, so incoming connections are denied for the selected Pod.

---

## 8. Lab C — Allow Only Client Pods

Now we will allow traffic from Pods labeled `app: client` to the Web Pod on TCP port 80.

Create a file named `allow-client.yaml`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-client-to-web
  namespace: day49-lab
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: client
      ports:
        - protocol: TCP
          port: 80
```

Apply the policy:

```bash
kubectl apply -f allow-client.yaml
```

Verify both policies:

```bash
kubectl get networkpolicy -n day49-lab
```

### Test 1 — Client Pod

```bash
kubectl exec -n day49-lab client -- curl -m 5 http://WEB_POD_IP
```

**Expected result:** The client request succeeds and returns the NGINX welcome page.

### Test 2 — Other Pod

```bash
kubectl exec -n day49-lab other -- curl -m 5 http://WEB_POD_IP
```

**Expected result:** The request fails or times out because the `other` Pod does not match the allowed source selector.

### Why does this work?

The destination selector:

```yaml
podSelector:
  matchLabels:
    app: web
```

selects the Web Pod.

The source selector:

```yaml
from:
  - podSelector:
      matchLabels:
        app: client
```

allows traffic only from client-labeled Pods in the same namespace.

The port rule:

```yaml
ports:
  - protocol: TCP
    port: 80
```

allows TCP traffic on port 80.

**Important:** NetworkPolicy rules are additive. The allow policy adds permission for matching client traffic; it does not remove other applicable allow rules.

---

## 9. Lab D — Understand Egress Restrictions

Egress policies control outgoing traffic from selected Pods.

For this investigation, create a separate policy file named `deny-client-egress.yaml`.

**Do not apply this policy to the main lab.** The exercise is to write and understand the policy, not to interrupt the working Pods.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-client-egress
  namespace: egress-lab
spec:
  podSelector:
    matchLabels:
      app: client
  policyTypes:
    - Egress
```

This policy selects Pods labeled `app: client` in the `egress-lab` namespace.

Because it has no egress allow rules, it denies all outgoing traffic from selected Pods when enforced.

### Why can DNS stop working?

DNS requests are outgoing network traffic.

If a Pod is isolated for egress and no DNS rule is allowed, DNS lookups can fail.

DNS commonly uses:

- UDP port 53
- TCP port 53

A suitable egress allow rule must permit traffic to the correct DNS destination and ports.

Do not assume every cluster uses the same DNS destination. Inspect the cluster's DNS Service and configuration before writing a production policy.

---

## 10. Useful Verification Commands

List NetworkPolicies across all namespaces:

```bash
kubectl get networkpolicy -A
```

List Pods and their labels:

```bash
kubectl get pods -n day49-lab --show-labels
```

Describe the default-deny policy:

```bash
kubectl describe networkpolicy deny-web-ingress -n day49-lab
```

Describe the allow policy:

```bash
kubectl describe networkpolicy allow-client-to-web -n day49-lab
```

Check Pod IP addresses:

```bash
kubectl get pods -n day49-lab -o wide
```

Check namespace resources:

```bash
kubectl get all -n day49-lab
```

---

## 11. Troubleshooting

### Problem 1 — NetworkPolicy has no effect

**Possible reason:** The cluster's CNI plugin does not support or enforce NetworkPolicy.

**Check:**

```bash
kubectl get pods -n kube-system -o wide
kubectl get daemonsets -A
minikube addons list
```

Verify the CNI implementation and its NetworkPolicy support.

### Problem 2 — Wrong Pods are selected

**Possible reason:** The Pod labels or namespace do not match the selectors.

**Check:**

```bash
kubectl get pods -n day49-lab --show-labels
```

Compare the labels with the policy's `podSelector` and source `podSelector`.

### Problem 3 — Allowed traffic still fails

Check:

- Whether the target Pod is Ready.
- Whether the Pod IP is correct.
- Whether the application is listening on the expected port.
- Whether the policy uses the correct protocol and port.
- Whether another applicable policy or an egress restriction affects the connection.

### Problem 4 — DNS stops working

**Possible reason:** An egress policy blocks DNS traffic.

DNS generally needs UDP and TCP port 53 to the correct DNS destination.

### Problem 5 — Connectivity test is inconclusive

Check the Pod IP and readiness:

```bash
kubectl get pods -n day49-lab -o wide
kubectl get pods -n day49-lab
```

Use a short curl timeout:

```bash
curl -m 5 http://WEB_POD_IP
```

A timeout alone does not prove that a NetworkPolicy is working. Confirm that the CNI enforces policies and compare the baseline result.

---

## 12. Interview Questions and Answers

### Q1. What is Kubernetes NetworkPolicy?

NetworkPolicy is a Kubernetes resource used to control incoming and outgoing network traffic for selected Pods.

### Q2. What is the difference between ingress and egress?

- Ingress: Incoming traffic entering a Pod.
- Egress: Outgoing traffic leaving a Pod.

### Q3. What does an empty `podSelector` select?

An empty `podSelector: {}` selects all Pods in the namespace where the NetworkPolicy is defined.

### Q4. Are Pods denied by default before any NetworkPolicy is applied?

No. NetworkPolicy does not automatically isolate all Pods. In the absence of applicable isolation policies, traffic is generally allowed by default, subject to the cluster's network implementation and other controls.

### Q5. Why does CNI support matter?

The CNI plugin implements the cluster networking behavior. A NetworkPolicy may be accepted by the Kubernetes API but have no enforcement effect if the network plugin does not support it.

### Q6. What is the difference between `podSelector` and `namespaceSelector`?

- `podSelector` selects Pods based on their labels.
- `namespaceSelector` selects namespaces based on their labels.

They can also be combined in a NetworkPolicy peer to select Pods with particular labels in matching namespaces.

### Q7. Why might DNS fail after applying an egress policy?

The egress policy may block DNS requests. DNS traffic generally requires UDP or TCP port 53 to the cluster's DNS destination.

### Q8. Are NetworkPolicy rules additive?

Yes. If multiple policies select a Pod, the allowed traffic is the union of the traffic permitted by those policies.

---

## 13. Cleanup

After completing the lab, delete only the dedicated Day49 namespace:

```bash
kubectl delete namespace day49-lab
```

Verify that it has been removed:

```bash
kubectl get namespace day49-lab
```

The expected result is that the namespace is not found.

**Safety note:** Do not delete other namespaces, shared networking components, the CNI plugin, or cluster-wide resources as part of this lab.

---

## 14. Important Notes

- NetworkPolicy is namespace-scoped.
- A NetworkPolicy selects Pods using labels.
- Ingress controls incoming traffic.
- Egress controls outgoing traffic.
- An empty ingress or egress rule list provides no allowed traffic in that direction for isolated selected Pods.
- Policies are additive.
- CNI support is essential for actual enforcement.
- DNS must be considered when restricting egress.
- Test policies in a dedicated namespace before using them in production.
- Never apply broad default-deny policies to shared or production namespaces without understanding application dependencies and preparing a rollback plan.

---

## 15. Day49 Summary

Day 49 introduces Kubernetes NetworkPolicy as a workload network-security mechanism.

The practical lab demonstrates how to:

1. Create a dedicated namespace and three Pods.
2. Test baseline connectivity.
3. Apply default-deny ingress to the Web Pod.
4. Allow only client-labeled Pods to access the Web Pod on TCP port 80.
5. Understand how egress restrictions can affect DNS.
6. Verify policy configuration and troubleshoot connectivity.

**Key takeaway:** NetworkPolicy helps control which workloads can communicate with each other, but effective enforcement depends on a compatible CNI plugin.
