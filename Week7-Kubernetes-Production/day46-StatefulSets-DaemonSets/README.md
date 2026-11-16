# Day 46 – Kubernetes Production: StatefulSets & DaemonSets

## Overview

**Day:** 46  
**Topic:** Kubernetes Production – StatefulSets & DaemonSets  
**Environment:** Minikube on WSL2 Ubuntu  
**Kubernetes Version:** v1.37.0  
**Minikube Version:** v1.39.0  
**Namespace:** `day46-lab`  
**Application:** NGINX (`nginx:1.27`)

## 1. Objectives

The objective of Day 46 is to understand how Kubernetes manages applications that require stable identity and applications that need to run on every eligible node.

By completing this lab, I will learn how to:

- Compare Deployment, StatefulSet and DaemonSet.
- Understand stable Pod names and ordinal identity.
- Understand ordered Pod creation and termination.
- Learn the purpose of headless Services.
- Create and manage a StatefulSet.
- Observe StatefulSet Pod recreation.
- Inspect existing DaemonSets in a Kubernetes cluster.
- Understand DaemonSet node placement and scheduling rules.
- Troubleshoot common StatefulSet and DaemonSet problems.

---

# 2. Core Concepts

## 2.1 Understanding Kubernetes Workload Controllers

Kubernetes provides different workload controllers to manage application Pods.

The three important workload controllers covered today are:

1. Deployment
2. StatefulSet
3. DaemonSet

Although all three manage Pods, they are designed for different application requirements.

### A. Deployment

A Deployment manages stateless applications by maintaining a specified number of interchangeable Pod replicas.

For example, suppose an application needs three NGINX replicas.

A Deployment creates and maintains three Pods.

If one Pod fails or is deleted, Kubernetes creates another Pod to maintain the desired replica count.

Example:

```text
Deployment: web-app

    |
    |-- Pod
    |-- Pod
    |-- Pod
```

**Important characteristics:**

- Designed primarily for stateless applications.
- Supports replica management.
- Supports rolling updates and rollbacks.
- Pods are generally interchangeable.
- Pod names are generated and are not guaranteed to remain the same after replacement.
- Does not provide stable ordinal identity for individual Pods.

**Real-world examples:**

- Frontend web applications.
- REST APIs.
- Backend application services.
- Stateless microservices.

### B. StatefulSet

A StatefulSet manages applications that require stable Pod identity and/or persistent storage.

Unlike Deployment, StatefulSet gives each Pod a predictable and unique ordinal name.

For example, a StatefulSet with two replicas creates:

```text
web-stateful-0
web-stateful-1
```

If `web-stateful-0` is deleted, Kubernetes recreates it with the same name.

This stable identity is useful for applications that need to identify individual instances.

**Important characteristics:**

- Provides stable Pod names.
- Assigns each Pod a unique ordinal index.
- Supports ordered Pod creation and termination.
- Supports stable network identity through a headless Service.
- Supports persistent storage through `volumeClaimTemplates`.
- Suitable for stateful and identity-sensitive applications.

**Real-world examples:**

- Database clusters.
- Distributed databases.
- Applications requiring stable member identities.
- Distributed systems that depend on predictable Pod identities.

### C. DaemonSet

A DaemonSet ensures that a Pod runs on every node eligible under its scheduling rules.

Unlike Deployment and StatefulSet, a DaemonSet is not normally used to maintain an arbitrary application replica count.

Instead, it provides node-level coverage.

For example, suppose a Kubernetes cluster has three eligible nodes.

A DaemonSet ensures that one instance of its Pod runs on each eligible node.

```text
             DaemonSet
                 |
       ---------------------
       |         |         |
     Node 1    Node 2    Node 3
       |         |         |
      Pod       Pod       Pod
```

**Important characteristics:**

- Ensures one Pod per eligible node.
- Automatically handles new eligible nodes.
- Removes or adjusts Pods when nodes become ineligible or are removed.
- Scheduling can be affected by node selectors, affinity, taints and tolerations.
- Commonly used for node-level infrastructure services.

**Real-world examples:**

- Log collection agents.
- Monitoring agents.
- Node networking components.
- Node-level security agents.

---

## 2.2 Detailed Difference: Deployment vs StatefulSet vs DaemonSet

| Feature | Deployment | StatefulSet | DaemonSet |
|---|---|---|---|
| Main purpose | Manage stateless application replicas | Manage stateful or identity-sensitive applications | Run a Pod on every eligible node |
| Pod identity | Generally interchangeable | Stable ordinal identity | One Pod per eligible node |
| Pod naming | Generated names | Predictable names such as app-0 and app-1 | Generated names |
| Replica management | User specifies replica count | User specifies replica count | Based on eligible nodes |
| Ordered creation | Not guaranteed | Supports ordered creation | Not the primary purpose |
| Ordered termination | Not guaranteed | Supports ordered termination | Not the primary purpose |
| Persistent storage | Can use volumes | Supports `volumeClaimTemplates` | Can use volumes |
| Network identity | Usually through a Service | Stable network identity through a headless Service | Not its primary purpose |
| Typical use | Frontend, APIs, microservices | Databases and distributed systems | Log collectors and monitoring agents |

### Practical example

**Deployment:**

```text
web-app-7f8d9c6b5-abcde
web-app-7f8d9c6b5-fghij
web-app-7f8d9c6b5-klmno
```

The Pods are interchangeable. If one is replaced, the new Pod does not need to keep the old Pod name.

**StatefulSet:**

```text
database-0
database-1
database-2
```

Each Pod has a stable ordinal identity.

For example, `database-0` remains the identity of the first StatefulSet Pod even when its underlying Pod instance is replaced.

**DaemonSet:**

```text
Node 1 -> log-agent Pod
Node 2 -> log-agent Pod
Node 3 -> log-agent Pod
```

The DaemonSet ensures that an agent runs on every eligible node.

### Key takeaway

- Deployment focuses on interchangeable application replicas.
- StatefulSet focuses on stable identity and stateful workload management.
- DaemonSet focuses on node-level coverage.

---

## 2.3 What is Stable Pod Identity?

Stable Pod identity means that a StatefulSet Pod receives a predictable name based on its StatefulSet name and ordinal index.

Example:

```text
web-stateful-0
web-stateful-1
web-stateful-2
```

The number at the end is called the **ordinal index**.

The first Pod has ordinal `0`, the second has ordinal `1`, and the third has ordinal `2`.

If `web-stateful-1` is deleted, the StatefulSet controller creates a replacement with the same ordinal identity.

This is important because some distributed applications need to identify individual instances consistently.

**Important distinction:** Stable Pod identity does not mean the same Pod process or container survives deletion. Kubernetes creates a replacement Pod with the same identity.

---

## 2.4 What is Ordered Pod Management?

StatefulSet supports ordered Pod creation and termination.

With the default `OrderedReady` Pod management policy:

- Kubernetes creates Pods in ordinal order.
- The next Pod is generally created after the previous Pod becomes Ready.
- During scale-down, Pods are terminated in reverse ordinal order.

Example with three replicas:

**Creation:**

```text
Step 1: application-0
Step 2: application-1
Step 3: application-2
```

**Termination during scale-down:**

```text
Step 1: application-2
Step 2: application-1
Step 3: application-0
```

This behaviour is useful for applications that depend on startup and shutdown order.

---

## 2.5 What is a Headless Service?

A normal Kubernetes Service generally provides a stable ClusterIP that clients use to access a group of Pods.

A headless Service works differently.

It is created using:

```yaml
clusterIP: None
```

This means Kubernetes does not allocate a normal virtual ClusterIP for that Service.

Instead, the Service provides DNS records for its selected endpoints.

Headless Services are commonly used with StatefulSets because applications may need to discover and communicate with individual Pods.

### Example

A StatefulSet named `web-stateful` uses a headless Service named `web-headless`.

The Pods can have DNS identities similar to:

```text
web-stateful-0.web-headless.day46-lab.svc.cluster.local

web-stateful-1.web-headless.day46-lab.svc.cluster.local
```

These names provide predictable network identities within the Kubernetes cluster.

### Normal Service vs Headless Service

| Feature | Normal Service | Headless Service |
|---|---|---|
| ClusterIP | Allocates a virtual ClusterIP | Uses `clusterIP: None` |
| DNS behaviour | Resolves to Service IP | Can resolve to individual endpoint addresses |
| Load balancing | Provides a common Service endpoint | Does not provide the normal virtual-IP load-balancing mechanism |
| Common use | Accessing application replicas | StatefulSet Pod discovery |

**Important:** A headless Service does not automatically guarantee that every Pod is reachable. Its selector, endpoints and cluster DNS must be configured and functioning correctly.

---

## 2.6 What is Persistent Storage in StatefulSet?

Stateful applications may need to preserve their data even when a Pod is deleted or recreated.

StatefulSet supports persistent storage using `volumeClaimTemplates`.

Example:

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
```

Kubernetes creates a separate PersistentVolumeClaim for each StatefulSet Pod.

For example:

```text
database-0 -> data-database-0
database-1 -> data-database-1
```

When a Pod is recreated, its associated PersistentVolumeClaim can be reused, allowing data to survive Pod replacement, subject to storage configuration and availability.

### Important: emptyDir vs PersistentVolumeClaim

| Feature | emptyDir | PersistentVolumeClaim |
|---|---|---|
| Storage type | Temporary Pod-associated storage | Persistent storage requested through Kubernetes |
| Survives container restart | Usually yes, while the Pod remains | Yes, subject to storage behaviour |
| Survives Pod deletion | No | Normally can be reused by a replacement Pod |
| Typical use | Temporary files and lab exercises | Databases and persistent application data |

**Day 46 lab note:** The supplied StatefulSet lab uses `emptyDir` to practise stable identity. It does not demonstrate persistent storage.

---

## 2.7 What is a DaemonSet?

A DaemonSet ensures that a Pod runs on each eligible node.

It is useful for applications that need to operate at the node level rather than simply serving application traffic.

### Example: Log collector

A log collector may need access to logs generated on every Kubernetes node.

A DaemonSet ensures that an agent runs on each eligible node.

```text
Kubernetes Cluster
        |
        v
    DaemonSet
        |
   -------------
   |     |     |
 Node 1 Node 2 Node 3
   |     |     |
 Agent Agent Agent
```

### Why not use a Deployment?

A Deployment maintains a specified number of replicas, but it does not guarantee one Pod on each node.

For example, a Deployment with three replicas could schedule all three Pods on one node if scheduling constraints allow it.

A DaemonSet is specifically designed for node-level coverage.

### Does a DaemonSet always run on every node?

No.

It runs on every node eligible under its scheduling rules.

Node selectors, node affinity, taints and tolerations can exclude nodes.

---

## 2.8 Understanding Node Selectors, Taints and Tolerations

These scheduling concepts are important when inspecting DaemonSets.

**Node Selector**

A node selector tells Kubernetes to schedule a Pod only on nodes that have the specified labels.

Example:

```yaml
nodeSelector:
  disktype: ssd
```

The Pod can be scheduled only on nodes labelled with:

```text
disktype=ssd
```

**Taints**

A taint marks a node so that Pods without an appropriate toleration are prevented from scheduling there, depending on the taint effect.

Example:

```bash
kubectl taint nodes NODE_NAME dedicated=database:NoSchedule
```

**Tolerations**

A toleration allows a Pod to be scheduled onto a node with a matching taint.

Example:

```yaml
tolerations:
  - key: dedicated
    operator: Equal
    value: database
    effect: NoSchedule
```

A DaemonSet may use tolerations so that its Pods can run on nodes that ordinary workloads cannot use.

---

# 3. Lab A – Create a Small StatefulSet

## Objective

Create a StatefulSet with two NGINX Pods and a headless Service.

The lab demonstrates:

- Stable Pod names.
- Ordered Pod creation.
- Headless Service configuration.
- StatefulSet inspection.
- Pod recreation with the same ordinal name.

The lab uses `emptyDir` for identity practice and does not demonstrate persistent storage.

## Step 1 – Create a Namespace

```bash
kubectl create namespace day46-lab
```

Explanation:

A separate namespace isolates Day 46 resources from previous labs.

Set the current kubectl context to use this namespace:

```bash
kubectl config set-context --current --namespace=day46-lab
```

This avoids having to specify `-n day46-lab` for every command.

Verify:

```bash
kubectl config view --minify | grep namespace
```

Expected:

```text
namespace: day46-lab
```

## Step 2 – Create the StatefulSet YAML

Create the file:

```bash
nano statefulset.yaml
```

Add the following configuration:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-headless
spec:
  clusterIP: None
  selector:
    app: web-stateful
  ports:
    - port: 80
      name: web
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
spec:
  serviceName: web-headless
  replicas: 2
  selector:
    matchLabels:
      app: web-stateful
  template:
    metadata:
      labels:
        app: web-stateful
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
          volumeMounts:
            - name: web-data
              mountPath: /usr/share/nginx/html
      volumes:
        - name: web-data
          emptyDir: {}
```

Save the file.

### Explanation of the YAML

This file defines two resources separated by `---`.

### Resource 1 – Headless Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-headless
```

- `apiVersion: v1` identifies the core Kubernetes API.
- `kind: Service` creates a Service.
- `name: web-headless` gives the Service its name.

Headless configuration:

```yaml
spec:
  clusterIP: None
```

This prevents Kubernetes from allocating a normal virtual ClusterIP.

Pod selector:

```yaml
selector:
  app: web-stateful
```

This Service selects Pods carrying the label `app: web-stateful`.

Port configuration:

```yaml
ports:
  - port: 80
    name: web
```

The Service exposes port 80.

### Resource 2 – StatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-stateful
```

This creates a StatefulSet named `web-stateful`.

### Service reference

```yaml
serviceName: web-headless
```

This connects the StatefulSet to the headless Service.

The Service must exist in the same namespace and have selectors that match the StatefulSet Pods.

### Replica configuration

```yaml
replicas: 2
```

This instructs Kubernetes to maintain two Pods.

### Selector configuration

```yaml
selector:
  matchLabels:
    app: web-stateful
```

The StatefulSet uses this selector to identify the Pods it manages.

### Pod template labels

```yaml
template:
  metadata:
    labels:
      app: web-stateful
```

These labels must match the StatefulSet selector.

### Container configuration

```yaml
containers:
  - name: nginx
    image: nginx:1.27
    ports:
      - containerPort: 80
```

This defines an NGINX container using image `nginx:1.27`.

The container listens on port 80.

### Volume mount

```yaml
volumeMounts:
  - name: web-data
    mountPath: /usr/share/nginx/html
```

This mounts the volume named `web-data` inside the NGINX container.

### Temporary volume

```yaml
volumes:
  - name: web-data
    emptyDir: {}
```

This creates temporary storage associated with the Pod.

The storage is removed when the Pod is deleted. It is included in this lab to practise volume configuration, not persistent storage.

## Step 3 – Apply the YAML

```bash
kubectl apply -f statefulset.yaml
```

This creates the headless Service and StatefulSet.

## Step 4 – Verify StatefulSet

```bash
kubectl get statefulsets
```

This displays the StatefulSets in the current namespace.

Check rollout:

```bash
kubectl rollout status statefulset/web-stateful
```

This waits until the StatefulSet rollout has completed.

## Step 5 – Verify Pods

```bash
kubectl get pods -o wide
```

Expected Pod names:

```text
web-stateful-0
web-stateful-1
```

The names demonstrate stable ordinal identity.

The Pods should eventually show `Running` and `1/1` Ready.

## Step 6 – Verify Service

```bash
kubectl get svc
```

Expected Service:

```text
NAME           TYPE        CLUSTER-IP   PORT(S)
web-headless   ClusterIP   None         80/TCP
```

The `CLUSTER-IP` value should be `None`.

This confirms that the Service is headless.

## Step 7 – Describe StatefulSet

```bash
kubectl describe statefulset web-stateful
```

This command provides details about:

- Desired replicas.
- Current replicas.
- Ready replicas.
- Pod template.
- Labels and selectors.
- Service name.
- Events.

It is useful for troubleshooting StatefulSet problems.

## Step 8 – Inspect EndpointSlices

```bash
kubectl get endpointslices
```

EndpointSlices contain the network endpoint information associated with Services.

Check that an EndpointSlice exists for `web-headless` and that its endpoints correspond to the StatefulSet Pods.

This helps verify that the Service selector is matching the intended Pods.

---

# 4. Lab A – Delete and Recreate a StatefulSet Pod

## Objective

Demonstrate that StatefulSet recreates a deleted Pod with the same ordinal name.

### Step 1 – Check existing Pods

```bash
kubectl get pods
```

Expected:

```text
NAME             READY   STATUS
web-stateful-0   1/1     Running
web-stateful-1   1/1     Running
```

### Step 2 – Delete the first Pod

```bash
kubectl delete pod web-stateful-0
```

This deletes the Pod instance.

It does not delete the StatefulSet.

### Step 3 – Watch Pod recreation

```bash
kubectl get pods --watch
```

Kubernetes detects that the StatefulSet has fewer Pods than its desired replica count.

The StatefulSet controller creates a replacement Pod.

The recreated Pod will again be named:

```text
web-stateful-0
```

Eventually, both Pods should return to Ready status.

Stop watching with:

```text
Ctrl + C
```

### Why does the Pod get the same name?

The StatefulSet controller maintains stable ordinal identities.

The deleted Pod was associated with ordinal zero.

Kubernetes therefore creates a replacement with the same identity:

```text
web-stateful-0
```

**Important:** The replacement is a new Pod instance. It does not mean the deleted Pod itself has returned.

Because this lab uses `emptyDir`, temporary data inside the deleted Pod is not preserved.

This demonstrates the difference between stable identity and persistent storage.

---

# 5. Lab B – Inspect Existing DaemonSets

## Objective

Inspect DaemonSets already running in the Kubernetes cluster.

A DaemonSet ensures that a Pod runs on every eligible node.

The lab focuses on identifying:

- Existing DaemonSets.
- Desired Pod count.
- Current Pod count.
- Ready Pod count.
- Node placement.
- Scheduling restrictions.

## Step 1 – List all DaemonSets

```bash
kubectl get daemonsets -A
```

Explanation:

- `get daemonsets` lists DaemonSet resources.
- `-A` lists resources across all namespaces.

Look for DaemonSets in namespaces such as:

```text
kube-system
ingress-nginx
```

The exact resources depend on the Minikube addons and cluster configuration.

## Step 2 – List Pods across all namespaces

```bash
kubectl get pods -A -o wide
```

Explanation:

- `-A` lists Pods from all namespaces.
- `-o wide` displays additional details, including Pod IP and node placement.

Inspect the `NODE` column to determine where DaemonSet Pods are running.

## Step 3 – Inspect Kubernetes nodes

```bash
kubectl get nodes -o wide
```

This displays the cluster's available nodes.

Compare the node list with the node placement of DaemonSet Pods.

A single-node Minikube cluster will normally have one eligible node for ordinary node-level DaemonSets.

## Step 4 – Choose a DaemonSet

First inspect the output:

```bash
kubectl get daemonsets -A
```

Choose an actual DaemonSet name and its namespace.

For example, if `kube-proxy` exists in `kube-system`, inspect it using:

```bash
kubectl describe daemonset kube-proxy -n kube-system
```

The name is an example. Use the actual DaemonSet available in the cluster.

## Step 5 – Understand DaemonSet counts

DaemonSet output contains columns such as:

```text
NAME       DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE
```

| Field | Meaning |
|---|---|
| Desired | Number of Pods the DaemonSet expects on eligible nodes |
| Current | Number of Pods currently created |
| Ready | Number of Pods that are Ready |
| Up-to-date | Number of Pods using the current Pod template |
| Available | Number of Pods considered available |

Example:

```text
NAME        DESIRED   CURRENT   READY
node-agent  1         1         1
```

This means:

- One eligible node requires the agent.
- One Pod has been created.
- The Pod is Ready.

## Step 6 – Inspect DaemonSet Pod placement

```bash
kubectl get pods -n NAMESPACE -o wide
```

Replace `NAMESPACE` with the actual namespace of the selected DaemonSet.

Compare the Pod placement with:

```bash
kubectl get nodes -o wide
```

This helps determine whether the DaemonSet is running on all eligible nodes.

## Step 7 – Understand why a DaemonSet may not run on every node

A DaemonSet does not automatically run on every node regardless of scheduling configuration.

Possible reasons include:

**Node selector**

A node selector may restrict the DaemonSet to nodes with particular labels.

**Node affinity**

Node affinity rules may restrict where the DaemonSet Pod can run.

**Taints and tolerations**

A node may have taints that prevent a Pod from scheduling unless the Pod has matching tolerations.

**Resource pressure**

A node may lack sufficient CPU or memory to run the DaemonSet Pod.

**Other scheduling restrictions**

Pod scheduling rules and node conditions can affect node eligibility.

---

# 6. Troubleshooting Guide

This section explains common problems encountered while working with StatefulSets and DaemonSets.

## 6.1 StatefulSet Pods remain Pending

### Problem

A StatefulSet Pod is created but remains in the `Pending` state.

Example:

```text
NAME             READY   STATUS
web-stateful-0   0/1     Pending
```

### Possible causes

- Insufficient node CPU.
- Insufficient node memory.
- Node selectors do not match.
- Node affinity requirements cannot be satisfied.
- Node taints prevent scheduling.
- PersistentVolumeClaim is not bound, if persistent storage is used.

### Troubleshooting commands

Check Pods:

```bash
kubectl get pods -n day46-lab
```

Describe the affected Pod:

```bash
kubectl describe pod web-stateful-0 -n day46-lab
```

Inspect node resources and conditions:

```bash
kubectl describe nodes
```

Check PersistentVolumeClaims if storage is configured:

```bash
kubectl get pvc -n day46-lab
```

Check events:

```bash
kubectl get events -n day46-lab --sort-by=.metadata.creationTimestamp
```

### Solution

Inspect the Pod's Events section to identify the scheduling problem.

Resolve resource shortages, node selector mismatches, taints, affinity restrictions, or PVC binding issues as appropriate.

---

## 6.2 StatefulSet Pods are not created

### Problem

The StatefulSet exists, but the expected Pods are missing.

### Possible causes

- Incorrect StatefulSet selector.
- Pod template labels do not match the selector.
- Invalid Pod template configuration.
- Image or scheduling problems.
- The StatefulSet references an incorrect Service name.

### Troubleshooting commands

Check StatefulSet:

```bash
kubectl get statefulsets -n day46-lab
```

Describe it:

```bash
kubectl describe statefulset web-stateful -n day46-lab
```

Inspect YAML:

```bash
kubectl get statefulset web-stateful -n day46-lab -o yaml
```

Check Pods:

```bash
kubectl get pods -n day46-lab -o wide
```

Check events:

```bash
kubectl get events -n day46-lab --sort-by=.metadata.creationTimestamp
```

### Solution

Verify that the selector and Pod template labels match.

For example:

```yaml
selector:
  matchLabels:
    app: web-stateful

template:
  metadata:
    labels:
      app: web-stateful
```

Also verify that the StatefulSet's `serviceName` references the intended headless Service.

---

## 6.3 Headless Service or Peer DNS fails

### Problem

StatefulSet Pods cannot resolve each other's DNS names.

Example:

```text
web-stateful-0.web-headless
```

does not resolve as expected.

### Possible causes

- Incorrect Service name.
- Service selector does not match Pod labels.
- EndpointSlices do not contain the expected Pod addresses.
- Pods are not Ready.
- Cluster DNS is not functioning.
- The DNS name or namespace is incorrect.

### Troubleshooting commands

Check Service:

```bash
kubectl get svc -n day46-lab
```

Describe Service:

```bash
kubectl describe svc web-headless -n day46-lab
```

Check EndpointSlices:

```bash
kubectl get endpointslices -n day46-lab
```

Check Pods and labels:

```bash
kubectl get pods -n day46-lab --show-labels
```

Check CoreDNS:

```bash
kubectl get pods -n kube-system
```

### Solution

Verify:

1. The headless Service has `clusterIP: None`.
2. The Service selector matches the StatefulSet Pod labels.
3. The StatefulSet `serviceName` references the correct Service.
4. EndpointSlices contain the expected endpoints.
5. Cluster DNS is functioning.

---

## 6.4 DaemonSet has fewer Ready Pods than expected

### Problem

The DaemonSet has fewer Ready Pods than the number of nodes expected.

### Possible causes

- Some nodes are not eligible.
- Node selectors exclude nodes.
- Node affinity rules are not satisfied.
- Taints and tolerations prevent scheduling.
- Image pulls are failing.
- Nodes have resource pressure.

### Troubleshooting commands

List DaemonSets:

```bash
kubectl get daemonsets -A
```

Describe the DaemonSet:

```bash
kubectl describe daemonset DAEMONSET_NAME -n NAMESPACE
```

List nodes:

```bash
kubectl get nodes -o wide
```

List Pods:

```bash
kubectl get pods -n NAMESPACE -o wide
```

Check events:

```bash
kubectl get events -n NAMESPACE --sort-by=.metadata.creationTimestamp
```

### Solution

Check the DaemonSet scheduling configuration and the node's conditions.

Verify node labels, taints, tolerations, resource availability and Pod events.

Remember that DaemonSet coverage is based on eligible nodes, not necessarily every node in the cluster.

---

## 6.5 ImagePullBackOff

### Problem

A StatefulSet or DaemonSet Pod cannot download its container image.

Example:

```text
STATUS: ImagePullBackOff
```

### Possible causes

- Incorrect image name.
- Incorrect image tag.
- Registry authentication problem.
- Network connectivity issue.
- Image is unavailable in the registry.

### Troubleshooting commands

Check Pods:

```bash
kubectl get pods -n day46-lab
```

Describe the affected Pod:

```bash
kubectl describe pod POD_NAME -n day46-lab
```

Check events:

```bash
kubectl get events -n day46-lab --sort-by=.metadata.creationTimestamp
```

### Solution

Verify the image name and tag in the Pod template.

Example:

```yaml
containers:
  - name: nginx
    image: nginx:1.27
```

Also verify registry access and network connectivity.

---

# 7. Useful Commands Reference

| Purpose | Command |
|---|---|
| Create namespace | `kubectl create namespace day46-lab` |
| Set default namespace | `kubectl config set-context --current --namespace=day46-lab` |
| Apply StatefulSet YAML | `kubectl apply -f statefulset.yaml` |
| List StatefulSets | `kubectl get statefulsets` |
| List StatefulSets across namespaces | `kubectl get sts -A` |
| Check StatefulSet Pods | `kubectl get pods -o wide` |
| Check Services | `kubectl get svc` |
| Describe StatefulSet | `kubectl describe statefulset web-stateful` |
| Check EndpointSlices | `kubectl get endpointslices` |
| Check StatefulSet rollout | `kubectl rollout status statefulset/web-stateful` |
| Delete StatefulSet Pod | `kubectl delete pod web-stateful-0` |
| Watch Pod recreation | `kubectl get pods --watch` |
| List DaemonSets | `kubectl get daemonsets -A` |
| List DaemonSet Pods | `kubectl get pods -A -o wide` |
| Check nodes | `kubectl get nodes -o wide` |
| Describe DaemonSet | `kubectl describe daemonset DAEMONSET_NAME -n NAMESPACE` |
| Inspect Pod | `kubectl describe pod POD_NAME -n NAMESPACE` |
| Check PVCs | `kubectl get pvc -n day46-lab` |
| Check events | `kubectl get events -n day46-lab --sort-by=.metadata.creationTimestamp` |
| Inspect StatefulSet YAML | `kubectl get statefulset web-stateful -o yaml` |

---

# 8. Interview Questions – Day 46

## Q1. What problem does StatefulSet solve that Deployment does not?

**Answer:**

Deployment manages interchangeable application replicas and does not provide stable ordinal identities.

StatefulSet provides stable Pod names, ordered management and support for persistent storage.

It is useful for applications that need predictable identities, such as databases and distributed systems.

## Q2. Why is a headless Service used with StatefulSets?

**Answer:**

A headless Service uses `clusterIP: None` and provides DNS records for individual StatefulSet Pods.

This allows applications to discover and communicate with specific Pod instances instead of relying only on a common Service endpoint.

## Q3. What does the ordinal in a StatefulSet Pod name mean?

**Answer:**

The ordinal is the index assigned to a StatefulSet Pod.

For example:

```text
database-0
database-1
database-2
```

The numbers represent the stable identity of each Pod.

The first Pod starts at ordinal zero.

## Q4. What is the purpose of a DaemonSet?

**Answer:**

A DaemonSet ensures that a Pod runs on every eligible node in a Kubernetes cluster.

It is mainly used for node-level services such as log collection, monitoring and networking agents.

## Q5. Give two real-world DaemonSet examples.

**Answer:**

1. Fluent Bit – A log collection agent that gathers logs from Kubernetes nodes.
2. Node monitoring agents – Agents that collect node-level CPU, memory and system metrics.

Other examples include networking components and node-level security agents.

## Q6. Does a DaemonSet always run on every node?

**Answer:**

No. A DaemonSet runs on every eligible node.

Node selectors, node affinity, taints and tolerations can affect which nodes are eligible for scheduling.

## Q7. What is the difference between StatefulSet and DaemonSet?

**Answer:**

StatefulSet manages a specified number of Pods with stable ordinal identities.

DaemonSet ensures that one Pod runs on every eligible node.

StatefulSet focuses on stable identity and stateful workload management, while DaemonSet focuses on node-level coverage.

## Q8. What happens when a StatefulSet Pod is deleted?

**Answer:**

The StatefulSet controller detects that the desired replica is missing and creates a replacement Pod with the same ordinal name.

For example, deleting `web-stateful-0` causes Kubernetes to recreate a Pod named `web-stateful-0`.

The new Pod is a different Pod instance.

## Q9. Does StatefulSet automatically preserve application data?

**Answer:**

No. Stable Pod identity does not automatically mean persistent data storage.

For persistent data, StatefulSet can use `volumeClaimTemplates` to create PersistentVolumeClaims for individual Pods.

## Q10. What is the difference between emptyDir and PersistentVolumeClaim?

**Answer:**

`emptyDir` provides temporary storage associated with a Pod and is removed when the Pod is deleted.

A PersistentVolumeClaim requests persistent storage that can normally be reused by a replacement Pod, depending on storage configuration.

## Q11. What is the difference between a normal Service and a headless Service?

**Answer:**

A normal Service provides a virtual ClusterIP and a common endpoint for accessing Pods.

A headless Service uses `clusterIP: None` and can provide DNS records for individual endpoints.

## Q12. What is OrderedReady in StatefulSet?

**Answer:**

`OrderedReady` is the default StatefulSet Pod management policy.

It creates Pods in ordinal order and generally waits for the previous Pod to become Ready before creating the next one.

During scale-down, Pods are terminated in reverse ordinal order.

## Q13. Why are stable network identities important for databases?

**Answer:**

Some distributed databases need predictable identities for their individual members.

Stable StatefulSet Pod names and headless Service DNS records help database members discover and communicate with one another.

## Q14. Why might a DaemonSet have fewer Pods than the number of cluster nodes?

**Answer:**

Some nodes may not be eligible because of node selectors, node affinity, taints, tolerations or other scheduling restrictions.

A DaemonSet does not necessarily run on every node without considering these rules.

## Q15. What is the difference between node selector and node affinity?

**Answer:**

Both influence Pod placement.

A node selector provides a straightforward way to require matching node labels.

Node affinity provides more expressive scheduling rules, including required and preferred placement conditions.

## Q16. What are taints and tolerations?

**Answer:**

Taints are applied to nodes to restrict which Pods can schedule onto them.

Tolerations are configured on Pods to allow them to be scheduled onto nodes with matching taints.

## Q17. What is the purpose of EndpointSlices?

**Answer:**

EndpointSlices contain network endpoint information associated with Kubernetes Services.

They help Kubernetes represent and manage the endpoints selected by a Service.

They are useful when troubleshooting Service discovery and StatefulSet networking.

## Q18. How would you troubleshoot a StatefulSet Pod stuck in Pending?

**Answer:**

I would inspect the Pod using:

```bash
kubectl describe pod POD_NAME -n day46-lab
```

Then I would check the Events section for scheduling problems.

I would also inspect node capacity, selectors, taints, affinity rules and PersistentVolumeClaims if storage is configured.

## Q19. How would you troubleshoot a DaemonSet that does not have the expected number of Ready Pods?

**Answer:**

I would use:

```bash
kubectl get daemonsets -A
kubectl describe daemonset DAEMONSET_NAME -n NAMESPACE
kubectl get nodes -o wide
kubectl get pods -n NAMESPACE -o wide
```

Then I would inspect node eligibility, taints, tolerations, image pull errors and resource pressure.

## Q20. Explain the difference between Deployment, StatefulSet and DaemonSet in a real-world project.

**Answer:**

In a production Kubernetes environment:

- I would use Deployment for stateless applications such as frontend services, APIs and microservices.
- I would use StatefulSet for databases or distributed systems that need stable Pod identity and persistent storage.
- I would use DaemonSet for node-level components such as log collectors, monitoring agents and networking services.

Each controller serves a different workload requirement.

---

# 9. Cleanup

After completing Day 46, delete only the namespace created for this assignment.

### Step 1 – Delete the Day 46 namespace

```bash
kubectl delete namespace day46-lab
```

This removes the namespaced resources created for the lab, including:

- `web-headless` Service.
- `web-stateful` StatefulSet.
- StatefulSet Pods.
- Associated ReplicaSets are not involved in this StatefulSet lab.
- Temporary `emptyDir` storage associated with the Pods.

### Step 2 – Verify namespace deletion

```bash
kubectl get namespace day46-lab
```

Expected:

```text
Error from server (NotFound): namespaces "day46-lab" not found
```

### Step 3 – Verify the cluster remains available

```bash
kubectl get nodes
```

### Important cleanup precautions

Do not delete the following existing resources:

- `day34-revision`
- `day44`
- `ingress-nginx`
- `kube-system`

These resources belong to previous labs or Kubernetes system components.

Only delete the disposable `day46-lab` namespace.

---

**Day 46 – Kubernetes Production: StatefulSets & DaemonSets**

*Understanding stable Pod identity, ordered workload management, headless Services, and node-level workload scheduling in Kubernetes.*
