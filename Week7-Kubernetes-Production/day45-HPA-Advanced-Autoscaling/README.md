# Day 45 – Kubernetes Production: HPA & Advanced Autoscaling

## Overview

**Day:** 45  
**Topic:** Kubernetes Production – HPA & Advanced Autoscaling  
**Environment:** Minikube on WSL2 Ubuntu 26.04  
**Kubernetes Version:** v1.37.0  
**Minikube Version:** v1.39.0  
**Namespace:** `day45-lab`  
**Application:** NGINX (`nginx:1.27`)

## 1. Objectives

The objective of Day 45 was to understand and implement Kubernetes Horizontal Pod Autoscaling (HPA).

By completing this lab, I learned how to:

- Understand Horizontal Pod Autoscaler (HPA).
- Configure CPU-based autoscaling for a Kubernetes Deployment.
- Enable Metrics Server and monitor CPU and memory utilization.
- Configure minimum and maximum replica counts.
- Understand CPU requests and their relationship with HPA.
- Observe automatic scaling based on CPU utilization.
- Understand stabilization windows and scaling policies.
- Differentiate Pod autoscaling from node autoscaling.
- Troubleshoot common HPA and autoscaling issues.

---

# 2. Core Concepts

## 2.1 What is Horizontal Pod Autoscaler (HPA)?

Horizontal Pod Autoscaler (HPA) is a Kubernetes resource that automatically adjusts the number of Pod replicas in a Deployment, ReplicaSet, or supported workload based on observed resource utilization or other configured metrics.

For example:

Suppose an application initially runs with two Pods.

When CPU utilization increases, HPA can increase the number of replicas to handle the additional workload.

When CPU utilization decreases, HPA can reduce the number of replicas, subject to its minimum replica count and scaling behaviour.

**Example:**

| Application load | Number of replicas |
|---|---:|
| Low | 2 |
| Increased | 3 |
| High | 4 |
| Very high | 5 |
| Decreased | Scales down gradually |

HPA helps applications handle changing workloads without manually changing replica counts.

## 2.2 How HPA works

The basic HPA workflow is:

1. Metrics Server collects resource usage information from Kubernetes nodes and Pods.
2. The Kubernetes Metrics API makes the collected metrics available.
3. The HPA controller periodically checks the current metrics.
4. HPA compares the observed utilization with the configured target.
5. It calculates the desired number of replicas.
6. Kubernetes adjusts the Deployment replica count.

**HPA workflow:**

```text
       Application Workload
                |
                v
          Kubernetes Pods
                |
                v
          Metrics Server
                |
                v
           Metrics API
                |
                v
        HPA Controller
                |
                v
     Compare CPU with Target
                |
                v
      Calculate Desired Pods
                |
                v
       Scale Deployment
```

HPA continuously evaluates the workload and makes scaling decisions based on available metrics.

## 2.3 What is Metrics Server?

Metrics Server is a Kubernetes component that collects resource metrics such as CPU and memory utilization from nodes and Pods.

It exposes these metrics through the Kubernetes Metrics API.

It is commonly used by:

- Horizontal Pod Autoscaler.
- `kubectl top nodes`.
- `kubectl top pods`.

Without an available Metrics API, CPU-based HPA cannot calculate utilization correctly.

**Important:** Metrics Server provides resource metrics. It is not a complete monitoring or long-term metrics storage solution like Prometheus.

## 2.4 What are CPU Requests?

CPU requests specify the amount of CPU resources requested by a container.

Kubernetes uses requests for scheduling and resource-utilization calculations.

For CPU utilization-based HPA, the utilization percentage is calculated relative to the CPU request.

Example:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 300m
    memory: 128Mi
```

Here:

- CPU request = 100 millicores.
- Memory request = 64 MiB.
- CPU limit = 300 millicores.
- Memory limit = 128 MiB.

If a container uses 50m CPU:

```text
CPU utilization = (CPU usage / CPU request) × 100

                = (50m / 100m) × 100

                = 50%
```

Therefore, if the HPA CPU target is 50%, the target average CPU usage is approximately 50m per container with a 100m CPU request.

**Important:** CPU requests are essential for utilization-based HPA calculations. If a relevant container does not have a CPU request, Kubernetes cannot calculate its CPU utilization percentage in the normal way.

## 2.5 Understanding HPA replica settings

Example:

```yaml
minReplicas: 2
maxReplicas: 5
```

- `minReplicas`: Minimum number of Pods HPA should maintain.
- `maxReplicas`: Maximum number of Pods HPA is allowed to create.

HPA cannot scale below the minimum or above the maximum.

## 2.6 Current Replicas vs Desired Replicas

These two values are important when troubleshooting autoscaling.

**Current replicas:** Number of replicas currently present in the workload.

**Desired replicas:** Number of replicas HPA or the workload controller wants to maintain.

Example:

```text
Current replicas: 2
Desired replicas: 4
```

This means Kubernetes is working toward running four replicas, but only two are currently present.

The difference can occur while new Pods are being created, scheduled, or becoming ready.

## 2.7 HPA vs Cluster Autoscaler

HPA and Cluster Autoscaler solve different scaling problems.

| Feature | HPA | Cluster Autoscaler |
|---|---|---|
| Scales | Pods | Worker nodes |
| Scaling level | Application | Infrastructure |
| Main purpose | Increase or decrease application capacity | Increase or decrease cluster node capacity |
| Trigger | CPU, memory, or other configured metrics | Conditions such as unschedulable Pods |
| Changes | Deployment replica count | Number of cluster nodes |

**Example:**

HPA increases an application from two Pods to five Pods.

If the existing worker node does not have enough resources to schedule all five Pods, some Pods may remain Pending.

A configured Cluster Autoscaler can add another worker node to provide additional capacity.

HPA itself does not add worker nodes.

---

# 3. Practical Implementation – Tasks A to D

## Task A – Inspect Existing Cluster Metrics and HPA Resources

### Objective

Inspect the existing Kubernetes cluster and check whether HPA resources and resource metrics are available.

### Step 1: Verify Kubernetes context

```bash
kubectl config current-context
```

Output:

```text
minikube
```

This confirmed that commands were being executed against the Minikube cluster.

### Step 2: Check existing HPA resources

```bash
kubectl get hpa -A
```

Output:

```text
No resources found
```

This confirmed that no HPA resources existed in the cluster before the Day 45 lab.

### Step 3: Check node metrics

```bash
kubectl top nodes
```

Initially, the command returned:

```text
error: Metrics API not available
```

This indicated that resource metrics were not available.

### Step 4: Check Pod metrics

```bash
kubectl top pods -A
```

This also failed because the Metrics API was unavailable.

### Step 5: Check Metrics Server Deployment

```bash
kubectl get deployment metrics-server -n kube-system
```

Output:

```text
Error from server (NotFound): deployments.apps "metrics-server" not found
```

This confirmed that Metrics Server was not installed in the cluster.

### Step 6: Enable Metrics Server in Minikube

```bash
minikube addons enable metrics-server
```

Minikube provides Metrics Server as an addon.

After enabling it, verify its Deployment:

```bash
kubectl get deployment metrics-server -n kube-system
```

Check rollout:

```bash
kubectl rollout status deployment/metrics-server -n kube-system --timeout=120s
```

Successful output:

```text
deployment "metrics-server" successfully rolled out
```

### Step 7: Verify node metrics again

```bash
kubectl top nodes
```

Observed output:

```text
NAME       CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
minikube   310m         2%       1099Mi          14%
```

### Step 8: Verify Pod metrics

```bash
kubectl top pods -A
```

This successfully displayed CPU and memory utilization for Pods across the cluster.

**Task A Result:** Completed successfully. Metrics Server was enabled, and the Metrics API became available.

---

## Task B – Create a Test Deployment with Resource Requests and Limits

### Objective

Create a test Deployment and configure CPU and memory requests and limits so HPA can calculate CPU utilization.

### Step 1: Create a namespace

```bash
kubectl create namespace day45-lab
```

Output:

```text
namespace/day45-lab created
```

A separate namespace was created to isolate the Day 45 lab resources.

### Step 2: Create the NGINX Deployment

```bash
kubectl create deployment web-demo --image=nginx:1.27 -n day45-lab
```

Output:

```text
deployment.apps/web-demo created
```

This created a Deployment named `web-demo` using the NGINX 1.27 image.

### Step 3: Configure CPU and memory requests and limits

```bash
kubectl set resources deployment/web-demo -n day45-lab --requests=cpu=100m,memory=64Mi --limits=cpu=300m,memory=128Mi
```

Output:

```text
deployment.apps/web-demo resource requirements updated
```

Resource configuration:

| Resource | Request | Limit |
|---|---:|---:|
| CPU | 100m | 300m |
| Memory | 64Mi | 128Mi |

**Explanation:**

- Requests specify the resources required by the container.
- Limits specify the maximum resources the container can consume.
- HPA uses the CPU request as the reference for calculating CPU utilization percentage.
- CPU limits help prevent a container from consuming unlimited CPU resources.

### Step 4: Verify Deployment

```bash
kubectl get deployment web-demo -n day45-lab
```

Observed output:

```text
NAME       READY   UP-TO-DATE   AVAILABLE
web-demo   1/1     1            1
```

### Step 5: Inspect the Deployment configuration

```bash
kubectl describe deployment web-demo -n day45-lab
```

This command displays the Deployment configuration, including container images, replica counts, resource requests, limits, and events.

**Task B Result:** Completed successfully. The NGINX Deployment was created with the required CPU and memory requests and limits.

---

## Task C – Configure Horizontal Pod Autoscaler

### Objective

Create an HPA for the `web-demo` Deployment with a CPU utilization target of 50%, a minimum of two replicas, and a maximum of five replicas.

### Step 1: Create HPA

```bash
kubectl autoscale deployment web-demo \
  -n day45-lab \
  --cpu-percent=50 \
  --min=2 \
  --max=5
```

Explanation:

| Parameter | Purpose |
|---|---|
| `deployment web-demo` | Target Deployment |
| `--cpu-percent=50` | Target average CPU utilization |
| `--min=2` | Minimum replicas |
| `--max=5` | Maximum replicas |

The command creates an HPA resource that automatically manages the Deployment's replica count.

### Step 2: Verify HPA

```bash
kubectl get hpa -n day45-lab
```

Observed output:

```text
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS
web-demo   Deployment/web-demo   cpu: 0%/50%   2         5         2
```

**Explanation:**

- Current CPU utilization was 0%.
- Target CPU utilization was 50%.
- Minimum replicas were 2.
- Maximum replicas were 5.
- HPA maintained two replicas.

### Step 3: Describe HPA

```bash
kubectl describe hpa web-demo -n day45-lab
```

Important observed conditions:

```text
AbleToScale     True
ScalingActive   True
ScalingLimited  False
```

Explanation:

- `AbleToScale: True` means HPA can perform scaling operations.
- `ScalingActive: True` means HPA has valid metrics and can calculate desired replicas.
- `ScalingLimited: False` means the desired replica count is within the configured range.

### Step 4: Inspect HPA YAML

```bash
kubectl get hpa web-demo -n day45-lab -o yaml
```

Important configuration:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler

spec:
  maxReplicas: 5

  metrics:
  - resource:
      name: cpu
      target:
        averageUtilization: 50
        type: Utilization
    type: Resource

  minReplicas: 2

  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-demo
```

This confirmed that the HPA was configured with the required CPU target and replica limits.

**Task C Result:** Completed successfully. HPA was created and successfully obtained CPU metrics from Metrics Server.

---

## Task D – Observe HPA Scaling Behaviour

### Objective

Monitor HPA and Pod metrics and observe how replica counts change when CPU utilization increases.

### Step 1: Monitor HPA continuously

```bash
kubectl get hpa -n day45-lab --watch
```

The `--watch` option continuously displays changes to HPA resources.

### Step 2: Monitor Pods

```bash
kubectl get pods -n day45-lab --watch
```

This displays Pod creation, termination, and status changes.

### Step 3: Check CPU and memory utilization

```bash
kubectl top pods -n day45-lab
```

This displays resource utilization for the Pods.

### Step 4: Identify NGINX Pods

```bash
kubectl get pods -n day45-lab -o wide
```

Observed Pod names:

```text
web-demo-f85cb4fc5-m644b
web-demo-f85cb4fc5-s64g2
```

Both Pods were running successfully.

### Step 5: Verify shell availability

```bash
kubectl exec -n day45-lab web-demo-f85cb4fc5-m644b -- sh -c 'echo "Shell is available"; command -v sh'
```

This verified that the NGINX container had a shell available for the controlled CPU test.

### Step 6: Generate controlled CPU load inside the NGINX containers

First NGINX Pod:

```bash
kubectl exec -n day45-lab web-demo-f85cb4fc5-m644b -- sh -c 'sh -c "while :; do :; done" & p=$!; sleep 30; kill "$p" 2>/dev/null; wait "$p" 2>/dev/null'
```

Second NGINX Pod:

```bash
kubectl exec -n day45-lab web-demo-f85cb4fc5-s64g2 -- sh -c 'sh -c "while :; do :; done" & p=$!; sleep 30; kill "$p" 2>/dev/null; wait "$p" 2>/dev/null'
```

**Explanation:**

- `while :; do :; done` creates a CPU-intensive loop.
- The process runs inside the actual NGINX container.
- `p=$!` stores the background process ID.
- `sleep 30` allows the CPU load to run for 30 seconds.
- `kill "$p"` terminates the background process.
- The NGINX container's configured CPU limit of 300m applies to its CPU consumption.

The command returned exit code 143 after terminating the background process. This is consistent with SIGTERM and did not indicate a Deployment failure.

**Safety note:** This was a short, controlled test in the isolated lab namespace. Do not run uncontrolled CPU stress tests on production workloads.

### Step 7: Observe HPA scaling

The HPA watch showed:

```text
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS
web-demo   Deployment/web-demo   cpu: 0%/50%   2         5         2

web-demo   Deployment/web-demo   cpu: 61%/50%   2         5         2

web-demo   Deployment/web-demo   cpu: 61%/50%   2         5         3

web-demo   Deployment/web-demo   cpu: 1%/50%    2         5         3
```

**What happened?**

1. Initially, HPA maintained two replicas.
2. CPU utilization increased to 61%.
3. The target was 50%.
4. Since actual utilization exceeded the target, HPA calculated a higher desired replica count.
5. The Deployment increased from two to three replicas.
6. After the CPU load stopped, CPU utilization decreased.
7. HPA later returned the desired replica count to the minimum of two.

The HPA events confirmed the scale-up:

```text
Normal  SuccessfulRescale  horizontal-pod-autoscaler
New size: 3; reason: cpu resource utilization (percentage of request) above target
```

This is direct evidence that CPU-based autoscaling worked successfully.

### Step 8: Verify final Pod metrics

```bash
kubectl top pods -n day45-lab
```

Observed output:

```text
NAME                       CPU(cores)   MEMORY(bytes)
web-demo-f85cb4fc5-4856m   0m           9Mi
web-demo-f85cb4fc5-m644b   0m           9Mi
web-demo-f85cb4fc5-s64g2   0m           9Mi
```

The output captured three Pods after the scale-up event.

### Step 9: Verify Deployment

```bash
kubectl get deployment web-demo -n day45-lab
```

Observed output:

```text
NAME       READY   UP-TO-DATE   AVAILABLE
web-demo   3/3     3            3
```

### Step 10: Inspect final HPA status

```bash
kubectl describe hpa web-demo -n day45-lab
```

Important conditions:

```text
AbleToScale     True
ScalingActive   True
ScalingLimited  False
```

HPA events included:

```text
SuccessfulRescale
New size: 2; reason: Current number of replicas below Spec.MinReplicas

SuccessfulRescale
New size: 3; reason: cpu resource utilization (percentage of request) above target
```

**Task D Result:** Completed successfully. CPU utilization reached 61%, exceeding the configured target of 50%, and HPA increased the Deployment from two to three replicas.

---

# 4. Task E – Advanced Autoscaling Concepts and Design

Task E focuses on understanding how Kubernetes controls scaling behaviour in production environments.

## 4.1 Design a scale-down stabilization window

### What is a scale-down stabilization window?

A scale-down stabilization window is a period during which HPA considers recent recommendations before reducing the number of replicas.

It prevents Kubernetes from immediately removing Pods when traffic or CPU usage decreases briefly.

### Why is it important?

Consider an application experiencing the following traffic pattern:

```text
10:00 AM – High traffic
10:01 AM – CPU increases
10:02 AM – HPA scales from 2 to 4 Pods
10:03 AM – Traffic decreases briefly
10:04 AM – Traffic increases again
```

Without suitable stabilization, Kubernetes could repeatedly increase and decrease the replica count.

This behaviour is known as **scaling flapping**.

Scaling flapping can cause:

- Unnecessary Pod creation and termination.
- Application instability.
- Increased infrastructure overhead.
- Unpredictable response times.
- Resource wastage.

### Proposed production-style configuration

A scale-down stabilization window can be configured using `behavior` in an HPA resource.

Example:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler

metadata:
  name: web-demo
  namespace: day45-lab

spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-demo

  minReplicas: 2
  maxReplicas: 5

  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50

  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
```

### Explanation

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300
```

- `behavior` controls how HPA performs scaling operations.
- `scaleDown` defines the scale-down behaviour.
- `stabilizationWindowSeconds: 300` defines a five-minute stabilization window.

During this window, HPA considers recent recommendations and selects a conservative recommendation to avoid scaling down too quickly.

**Important:** This is a proposed design example. The custom behavior configuration was not applied to the Day 45 HPA during this lab. The practical scale-up and scale-down observations were performed using the HPA created with `kubectl autoscale`.

## 4.2 Explain scale-up and scale-down policies

HPA supports scaling policies to control how quickly replica counts can change.

These policies help prevent sudden, excessive changes in application capacity.

### Scale-up policies

Scale-up policies control how quickly HPA can add replicas.

Example:

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0
    policies:
    - type: Pods
      value: 2
      periodSeconds: 60
```

Explanation:

- `stabilizationWindowSeconds: 0` means no additional scale-up stabilization delay.
- `type: Pods` defines an absolute Pod-count change.
- `value: 2` allows up to two additional Pods under this policy.
- `periodSeconds: 60` defines the policy period.

This policy allows HPA to add up to two Pods during a 60-second period, subject to the HPA's other limits and scaling rules.

### Scale-down policies

Scale-down policies control how quickly HPA removes replicas.

Example:

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
    - type: Pods
      value: 1
      periodSeconds: 60
```

Explanation:

- `stabilizationWindowSeconds: 300` provides a five-minute stabilization window.
- `type: Pods` defines an absolute Pod-count change.
- `value: 1` allows a reduction of one Pod.
- `periodSeconds: 60` defines the policy period.

This creates a more gradual scale-down process.

### Pods policy vs Percent policy

HPA supports two important scaling policy types:

| Policy type | Explanation | Example |
|---|---|---|
| Pods | Limits the absolute number of Pods added or removed | Add at most 2 Pods |
| Percent | Limits the percentage change in replica count | Increase by at most 50% |

**Important:** HPA can have multiple policies. The `selectPolicy` setting controls how HPA chooses between them. By default, HPA selects the policy that allows the largest change.

Stabilization windows and scaling policies work together:

- Stabilization windows help prevent reactions to short-lived metric changes.
- Scaling policies limit the rate of replica changes.

## 4.3 What happens when HPA reaches maxReplicas?

Suppose:

```yaml
minReplicas: 2
maxReplicas: 5
```

The application experiences increasing traffic.

HPA scales:

```text
2 Pods → 3 Pods → 4 Pods → 5 Pods
```

Now CPU utilization continues increasing.

HPA cannot scale beyond five Pods because the maximum replica count is five.

The HPA may report that scaling is limited by the configured maximum.

Example condition:

```text
ScalingLimited: True
```

The exact condition reason and message depend on the current HPA status.

### What are the consequences?

- The application continues running with five replicas.
- HPA cannot create additional replicas beyond the configured maximum.
- CPU utilization may remain high.
- Application response times may increase.
- Requests may become slower or fail if the application is overloaded.

### How can this be addressed?

1. Review whether the maximum replica count should be increased.
2. Check available node resources.
3. Optimize application performance.
4. Review CPU requests and limits.
5. Consider additional worker nodes when cluster capacity is insufficient.
6. Review whether the configured scaling metric and target are appropriate.

**Production lesson:** Setting `maxReplicas` is important because it places a limit on application scaling and helps control infrastructure consumption.

## 4.4 Why might a Pod remain Pending after HPA adds replicas?

HPA controls the number of desired Pods, but it does not guarantee that every Pod can be scheduled.

Suppose HPA scales a Deployment from two replicas to five replicas.

The Kubernetes scheduler must find sufficient resources on available nodes to run the new Pods.

If resources are insufficient, some Pods may remain in the `Pending` state.

### Common reasons

**1. Insufficient CPU or memory**

The node does not have enough available resources to satisfy the Pod's resource requests.

**2. Node taints**

A node has taints that prevent the Pod from being scheduled unless the Pod has matching tolerations.

**3. Node selectors**

The Pod requires a particular node label, but no available node matches the selector.

**4. Node affinity**

The Pod has node-affinity rules that cannot be satisfied by available nodes.

**5. Persistent Volume Claims**

A Pod requires storage, but its Persistent Volume Claim cannot be bound or its storage requirements cannot be satisfied.

**6. Availability Zone constraints**

Storage or scheduling constraints may prevent a Pod from running in an available zone.

### How to troubleshoot Pending Pods

```bash
kubectl get pods -n day45-lab
```

Inspect a Pending Pod:

```bash
kubectl describe pod POD_NAME -n day45-lab
```

Check node resources:

```bash
kubectl describe nodes
```

Check node labels:

```bash
kubectl get nodes --show-labels
```

Check events:

```bash
kubectl get events -n day45-lab --sort-by=.lastTimestamp
```

### How does Cluster Autoscaler help?

Cluster Autoscaler monitors the cluster for unschedulable Pods and can increase the number of worker nodes when its configuration and infrastructure provider allow it.

Example:

```text
HPA increases replicas
        |
        v
New Pods are created
        |
        v
Scheduler cannot place all Pods
        |
        v
Some Pods remain Pending
        |
        v
Cluster Autoscaler detects unschedulable Pods
        |
        v
Additional worker node is added
        |
        v
Pending Pods may become schedulable
```

**Important:** Cluster Autoscaler is a separate component. It must be installed and configured for the cluster and infrastructure provider. Minikube does not automatically add worker nodes just because HPA scales a Deployment.

---

# 5. Troubleshooting HPA

This section covers common issues encountered when implementing Kubernetes autoscaling.

## 5.1 Unknown metrics

### Problem

Running:

```bash
kubectl get hpa -n day45-lab
```

May display:

```text
TARGETS
<unknown>/50%
```

### Possible causes

- Metrics Server is not installed.
- Metrics Server is not running.
- Metrics API is unavailable.
- API aggregation is not functioning correctly.
- Resource requests are missing.
- Metrics are not yet available.

### Troubleshooting commands

Check Metrics Server:

```bash
kubectl get deployment metrics-server -n kube-system
```

Check its Pods:

```bash
kubectl get pods -n kube-system | grep metrics-server
```

Check rollout:

```bash
kubectl rollout status deployment/metrics-server -n kube-system
```

Check Metrics API:

```bash
kubectl get apiservices | grep metrics
```

Check node metrics:

```bash
kubectl top nodes
```

Check Pod metrics:

```bash
kubectl top pods -n day45-lab
```

Inspect HPA:

```bash
kubectl describe hpa web-demo -n day45-lab
```

Check events:

```bash
kubectl get events -n day45-lab --sort-by=.lastTimestamp
```

**Solution:** Ensure Metrics Server is healthy, the Metrics API is available, CPU requests are configured, and metrics have had time to become available.

## 5.2 Missing CPU utilization

### Problem

HPA cannot calculate CPU utilization correctly.

### Possible cause

CPU requests are missing from one or more relevant containers.

For utilization-based HPA, CPU usage is measured relative to CPU requests.

### Troubleshooting

```bash
kubectl describe deployment web-demo -n day45-lab
```

Inspect the container resources:

```bash
kubectl get deployment web-demo -n day45-lab -o yaml
```

Expected configuration:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 300m
    memory: 128Mi
```

**Solution:** Configure CPU requests for all relevant containers in the Pods whose CPU utilization is being measured.

## 5.3 Replicas do not increase

### Problem

CPU utilization increases, but the HPA does not increase the replica count.

### Possible causes

- CPU utilization is below the target.
- Metrics are unavailable.
- CPU requests are missing.
- The workload is not generating enough CPU activity.
- The maximum replica count has been reached.
- HPA has not yet completed its next reconciliation cycle.

### Troubleshooting

Check HPA:

```bash
kubectl get hpa -n day45-lab
```

Inspect HPA details:

```bash
kubectl describe hpa web-demo -n day45-lab
```

Check CPU usage:

```bash
kubectl top pods -n day45-lab
```

Check Deployment:

```bash
kubectl get deployment web-demo -n day45-lab
```

Check events:

```bash
kubectl get events -n day45-lab --sort-by=.lastTimestamp
```

**Solution:** Verify the target percentage, current CPU utilization, min/max limits, workload activity, resource requests, and HPA events.

## 5.4 Pods remain Pending

### Problem

HPA creates additional replicas, but some Pods remain Pending.

### Possible causes

- Insufficient node CPU.
- Insufficient node memory.
- Node taints and missing tolerations.
- Node selector mismatch.
- Node affinity constraints.
- Persistent Volume Claim problems.
- Availability Zone or storage constraints.

### Troubleshooting

```bash
kubectl get pods -n day45-lab
```

```bash
kubectl describe pod POD_NAME -n day45-lab
```

```bash
kubectl describe nodes
```

```bash
kubectl get nodes --show-labels
```

```bash
kubectl get events -n day45-lab --sort-by=.lastTimestamp
```

**Solution:** Inspect the Pod scheduling events and determine whether the problem is resource capacity, node constraints, or storage configuration. Add node capacity where appropriate.

## 5.5 Replicas fluctuate frequently

### Problem

HPA repeatedly increases and decreases the number of replicas.

This is called scaling flapping.

### Possible causes

- Noisy CPU metrics.
- Short traffic spikes.
- Unstable workloads.
- Aggressive scale-down behaviour.
- Poorly selected CPU utilization targets.
- Missing stabilization settings.

### Solution

Use HPA behavior configuration:

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300
```

Use scaling policies to control how quickly replicas can be added or removed.

Also review the workload's CPU request, scaling target, and traffic pattern.

**Production lesson:** Autoscaling should respond to real demand without creating unnecessary scaling activity.

---

# 6. Interview Quick Check – Day 45

These questions focus on the concepts and practical work covered today.

## Q1. What is Horizontal Pod Autoscaler?

**Answer:**

HPA is a Kubernetes resource that automatically increases or decreases the number of Pod replicas based on observed metrics such as CPU and memory utilization.

## Q2. What does HPA scale?

**Answer:**

HPA scales the number of Pod replicas in supported Kubernetes workloads, such as Deployments and ReplicaSets. It does not directly scale worker nodes.

## Q3. Why is Metrics Server required for CPU-based HPA?

**Answer:**

Metrics Server collects CPU and memory resource metrics from Kubernetes nodes and Pods and exposes them through the Metrics API. HPA uses these metrics to calculate the desired replica count.

## Q4. Why are CPU requests needed for utilization-based HPA?

**Answer:**

HPA calculates CPU utilization as a percentage of the CPU request.

For example, if CPU request is 100m and CPU usage is 50m:

```text
(50m / 100m) × 100 = 50%
```

Without a CPU request for a relevant container, Kubernetes cannot calculate its CPU utilization percentage in the normal way.

## Q5. What is the difference between CPU request and CPU limit?

**Answer:**

- CPU request is the amount of CPU requested by a container and is used for scheduling and utilization calculations.
- CPU limit is the maximum CPU amount the container is allowed to consume.

## Q6. What is the difference between current and desired replicas?

**Answer:**

Current replicas represent the number of replicas currently running or present in the workload.

Desired replicas represent the number of replicas Kubernetes wants to maintain.

For example, if current replicas are 2 and desired replicas are 4, Kubernetes is working toward running four replicas.

## Q7. What is minReplicas?

**Answer:**

`minReplicas` specifies the minimum number of Pod replicas that HPA should maintain.

Example:

```yaml
minReplicas: 2
```

HPA should not scale below two replicas.

## Q8. What is maxReplicas?

**Answer:**

`maxReplicas` specifies the maximum number of replicas HPA can create.

Example:

```yaml
maxReplicas: 5
```

HPA cannot scale above five replicas.

## Q9. What happens when maxReplicas is reached?

**Answer:**

HPA cannot create additional replicas beyond the configured maximum. If demand continues increasing, existing Pods may become overloaded, resulting in higher CPU usage, increased latency, or failed requests.

The maximum can be reviewed, and additional cluster capacity or application optimization may be required.

## Q10. What is a stabilization window?

**Answer:**

A stabilization window is a period during which HPA considers recent scaling recommendations before changing replica counts.

It helps prevent rapid scaling changes caused by short-lived traffic or metric fluctuations.

## Q11. How do stabilization windows reduce scaling flaps?

**Answer:**

They prevent HPA from immediately reacting to temporary decreases in demand. By considering recent recommendations, HPA can make more stable scale-down decisions.

## Q12. What is the difference between scale-up and scale-down policies?

**Answer:**

Scale-up policies control how quickly replicas can be added.

Scale-down policies control how quickly replicas can be removed.

They can limit the number or percentage of Pods changed during a specified period.

## Q13. What is the difference between Pods policy and Percent policy?

**Answer:**

- Pods policy limits an absolute number of Pods.
- Percent policy limits the percentage change in the replica count.

For example, a Pods policy may allow two additional Pods, while a Percent policy may allow a 50% increase.

## Q14. Why can a Pod remain Pending after HPA scales up?

**Answer:**

HPA can create additional desired replicas, but the Kubernetes scheduler still needs to find a suitable node.

A Pod may remain Pending because of insufficient CPU or memory, taints, node selectors, affinity rules, or storage constraints.

## Q15. How can Cluster Autoscaler help?

**Answer:**

Cluster Autoscaler can add worker nodes when Pods cannot be scheduled because of insufficient cluster capacity, provided the autoscaler and infrastructure integration are configured correctly.

## Q16. What is the difference between HPA and Cluster Autoscaler?

**Answer:**

HPA scales application Pods, while Cluster Autoscaler scales the number of worker nodes.

HPA manages application capacity, whereas Cluster Autoscaler manages cluster infrastructure capacity.

## Q17. How do you troubleshoot Unknown metrics in HPA?

**Answer:**

Check whether Metrics Server is installed and running, verify the Metrics API and API aggregation, check resource requests, inspect HPA conditions, and review Kubernetes events.

Commands:

```bash
kubectl get deployment metrics-server -n kube-system
kubectl get apiservices | grep metrics
kubectl top nodes
kubectl top pods -n day45-lab
kubectl describe hpa web-demo -n day45-lab
```

## Q18. How do you check why a Pod is Pending?

**Answer:**

Use:

```bash
kubectl describe pod POD_NAME -n day45-lab
```

Inspect the Events section to identify scheduling errors, resource shortages, taints, affinity constraints, or storage problems.

## Q19. What is the purpose of `kubectl top pods`?

**Answer:**

It displays current CPU and memory utilization for Pods, provided the Metrics API is available.

## Q20. Explain what happened in your Day 45 practical.

**Answer:**

I enabled Metrics Server in Minikube, created an NGINX Deployment, configured CPU and memory requests and limits, and created an HPA with a 50% CPU utilization target, minimum two replicas, and maximum five replicas.

I generated controlled CPU load inside the NGINX containers. HPA observed CPU utilization at 61%, exceeding the 50% target, and increased the Deployment from two to three replicas.

After the load stopped, CPU utilization decreased and HPA eventually returned the desired replica count to two.

This demonstrated CPU-based horizontal autoscaling in Kubernetes.

---

# 7. Important Commands Reference

| Purpose | Command |
|---|---|
| Check current context | `kubectl config current-context` |
| List all HPA resources | `kubectl get hpa -A` |
| Enable Metrics Server | `minikube addons enable metrics-server` |
| Check Metrics Server | `kubectl get deployment metrics-server -n kube-system` |
| Check node metrics | `kubectl top nodes` |
| Check Pod metrics | `kubectl top pods -n day45-lab` |
| Create namespace | `kubectl create namespace day45-lab` |
| Create Deployment | `kubectl create deployment web-demo --image=nginx:1.27 -n day45-lab` |
| Configure resources | `kubectl set resources deployment/web-demo -n day45-lab --requests=cpu=100m,memory=64Mi --limits=cpu=300m,memory=128Mi` |
| Create HPA | `kubectl autoscale deployment web-demo -n day45-lab --cpu-percent=50 --min=2 --max=5` |
| Check HPA | `kubectl get hpa -n day45-lab` |
| Describe HPA | `kubectl describe hpa web-demo -n day45-lab` |
| Inspect HPA YAML | `kubectl get hpa web-demo -n day45-lab -o yaml` |
| Monitor HPA | `kubectl get hpa -n day45-lab --watch` |
| Monitor Pods | `kubectl get pods -n day45-lab --watch` |
| Check Deployment | `kubectl get deployment web-demo -n day45-lab` |
| Inspect Pod | `kubectl describe pod POD_NAME -n day45-lab` |
| Check events | `kubectl get events -n day45-lab --sort-by=.lastTimestamp` |

---

### Practical Results

- Metrics Server successfully enabled in Minikube.
- Kubernetes Metrics API became available.
- NGINX Deployment created successfully.
- CPU request configured to 100m.
- CPU limit configured to 300m.
- Memory request configured to 64Mi.
- Memory limit configured to 128Mi.
- HPA configured with 50% CPU utilization target.
- Minimum replicas configured as 2.
- Maximum replicas configured as 5.
- CPU utilization reached 61% during the controlled test.
- HPA successfully scaled the Deployment from 2 to 3 replicas.
- HPA subsequently reduced the desired replica count after CPU utilization decreased.

### Final Learning

Day 45 demonstrated how Kubernetes automatically adjusts application capacity based on CPU utilization.

I learned that HPA depends on resource metrics and CPU requests, while stabilization windows and scaling policies help maintain predictable scaling behaviour.

I also understood that HPA and Cluster Autoscaler operate at different levels: HPA scales application Pods, while Cluster Autoscaler scales the underlying worker nodes.

---

# 8. Cleanup

After completing the lab, delete only the disposable Day 45 namespace:

```bash
kubectl delete namespace day45-lab
```

Verify:

```bash
kubectl get namespaces
```

**Important:** Do not delete the existing `day34-revision`, `day44`, or `ingress-nginx` namespaces. Keep the Metrics Server addon enabled because it may be useful for subsequent Kubernetes labs.

---

**Day 45 – Kubernetes Production: HPA & Advanced Autoscaling**

*Learned, implemented, observed, and documented CPU-based horizontal autoscaling using Kubernetes HPA on Minikube.*
