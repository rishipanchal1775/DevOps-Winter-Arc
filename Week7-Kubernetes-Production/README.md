# Day 50 — Kubernetes Production: Break-and-Fix Lab

## Overview

Day 50 focuses on troubleshooting and fixing common Kubernetes problems through a practical Break-and-Fix Lab.

Instead of only deploying working applications, this lab deliberately introduces errors into Kubernetes resources. We investigate the symptoms, identify the root causes, apply the smallest safe fixes, and verify recovery.

**Environment:** Minikube / Kubernetes  
**Namespace:** `day50-lab`  
**Main topics:** Kubernetes troubleshooting, ImagePullBackOff, CrashLoopBackOff, Services, PVC, NetworkPolicy

---

## 1. Learning Objectives

By completing this lab, you should understand:

- How to follow an evidence-based Kubernetes troubleshooting workflow.
- How to diagnose and fix ImagePullBackOff.
- How to investigate and repair CrashLoopBackOff.
- How to diagnose Service selector mismatches.
- How to investigate PVC Pending issues.
- How to investigate NetworkPolicy behavior.
- How to inspect Kubernetes events and container logs.
- How to verify fixes and document root causes.

---

## 2. Safety and Lab Setup

This lab should be performed in a local Minikube or Kind cluster, not in a production or shared cluster.

All resources created for this exercise must remain inside:

```text
day50-lab
```

### Verify the Kubernetes context

```bash
kubectl config current-context
minikube status
kubectl get nodes -o wide
```

### Create the namespace

```bash
kubectl create namespace day50-lab
```

Set the current context's default namespace:

```bash
kubectl config set-context --current --namespace=day50-lab
```

Verify:

```bash
kubectl get namespaces
kubectl config view --minify | grep namespace
```

**Important:** Before running destructive commands, confirm the current context. Modify only resources belonging to `day50-lab`.

---

## 3. Kubernetes Troubleshooting Workflow

A good Kubernetes engineer should follow a systematic troubleshooting process.

### Step 1 — Observe the symptom

Identify what is not working.

Examples:

- ImagePullBackOff
- CrashLoopBackOff
- Service without endpoints
- PVC stuck in Pending

### Step 2 — Inspect status and events

```bash
kubectl get all -n day50-lab
kubectl get pods -o wide -n day50-lab
kubectl get events -n day50-lab
```

### Step 3 — Check logs and configuration

```bash
kubectl describe pod POD_NAME -n day50-lab
kubectl logs POD_NAME -n day50-lab
kubectl logs POD_NAME --previous -n day50-lab
```

### Step 4 — Identify the root cause

Understand why the resource is failing before changing anything.

### Step 5 — Apply the smallest safe fix

Change only the configuration responsible for the problem.

### Step 6 — Verify recovery

```bash
kubectl get pods -n day50-lab
kubectl get deployments -n day50-lab
```

The main troubleshooting workflow is:

```text
Observe
   |
   v
Inspect Status and Events
   |
   v
Check Logs and Configuration
   |
   v
Identify Root Cause
   |
   v
Apply Smallest Safe Fix
   |
   v
Verify Recovery
```

---

## 4. Exercise A — Fix ImagePullBackOff

### Objective

Create a Deployment with an invalid image tag, identify the image pull error, and repair the Deployment.

### Step 1 — Create a broken Deployment

```bash
kubectl create deployment bad-image \
  --image=nginx:tag-does-not-exist \
  -n day50-lab
```

### Step 2 — Check Pod status

```bash
kubectl get pods -n day50-lab
```

Expected status after the image pull failure:

```text
NAME                         READY   STATUS
bad-image-xxxxxxxxxx-xxxxx   0/1     ImagePullBackOff
```

The Pod may initially show `ErrImagePull`.

### Step 3 — Investigate the failure

Find the Pod name:

```bash
kubectl get pods -n day50-lab
```

Describe the Pod:

```bash
kubectl describe pod POD_NAME -n day50-lab
```

Inspect the Events section.

You should find an image pull error because the requested image tag does not exist.

### Step 4 — Repair the Deployment

Update the image to a valid version:

```bash
kubectl set image deployment/bad-image nginx=nginx:1.27 -n day50-lab
```

### Step 5 — Verify the repair

```bash
kubectl rollout status deployment/bad-image -n day50-lab
kubectl get pods -n day50-lab
kubectl get deployment bad-image -n day50-lab
```

Expected result:

The Deployment becomes available and the Pod reaches:

```text
READY   STATUS
1/1     Running
```

### Root Cause

The Deployment referenced an invalid container image tag.

### Fix

Changed the image to:

```text
nginx:1.27
```

### Prevention

- Verify image names and tags before deployment.
- Use tested image versions.
- Avoid deploying unverified image tags.

---

## 5. Exercise B — Fix CrashLoopBackOff

### Objective

Create a container that exits immediately, investigate its logs, and repair its command.

### Step 1 — Create a crashing Deployment

```bash
kubectl create deployment crash-demo \
  --image=busybox:1.36 \
  -n day50-lab \
  -- /bin/sh -c "exit 1"
```

### Step 2 — Check Pod status

```bash
kubectl get pods -n day50-lab
```

Expected status:

```text
NAME                          READY   STATUS
crash-demo-xxxxxxxxxx-xxxxx   0/1     CrashLoopBackOff
```

### Step 3 — Investigate container logs

Find the Pod name:

```bash
kubectl get pods -n day50-lab
```

Check current logs:

```bash
kubectl logs POD_NAME -n day50-lab
```

Check previous container logs:

```bash
kubectl logs POD_NAME --previous -n day50-lab
```

Inspect the Pod:

```bash
kubectl describe pod POD_NAME -n day50-lab
```

### Why does the container crash?

The command:

```bash
exit 1
```

immediately terminates the container with a non-zero exit code.

Kubernetes restarts the container according to its restart policy. Repeated failures result in `CrashLoopBackOff`.

### Step 4 — Repair the Deployment

Edit the Deployment:

```bash
kubectl edit deployment crash-demo -n day50-lab
```

Find the container specification and change its command to:

```yaml
command:
  - sh
  - -c
  - sleep 36000
```

Save and exit the editor.

### Step 5 — Verify the repair

```bash
kubectl rollout status deployment/crash-demo -n day50-lab
kubectl get pods -n day50-lab
```

Expected result:

The `crash-demo` Pod should reach `1/1 Running`.

### Root Cause

The container's main process exited immediately with exit code 1.

### Fix

Changed the container command to a long-running process:

```bash
sleep 36000
```

### Prevention

- Test container commands and entrypoints.
- Ensure the main container process stays alive as intended.
- Inspect logs and exit codes when containers repeatedly restart.

---

## 6. Exercise C — Fix Service Selector Mismatch

### Objective

Create a Web Deployment and Service, deliberately break the Service selector, investigate the missing endpoints, and restore the correct selector.

### Step 1 — Create a Web Deployment

```bash
kubectl create deployment web-demo \
  --image=nginx:1.27 \
  -n day50-lab
```

Check Pod labels:

```bash
kubectl get pods -n day50-lab --show-labels
```

The Deployment normally creates Pods with:

```text
app=web-demo
```

### Step 2 — Expose the Deployment

```bash
kubectl expose deployment web-demo \
  --name=web-svc \
  --port=80 \
  --target-port=80 \
  -n day50-lab
```

Check the Service:

```bash
kubectl get svc web-svc -n day50-lab
```

### Step 3 — Deliberately break the Service selector

```bash
kubectl patch service web-svc -n day50-lab \
  -p '{"spec":{"selector":{"app":"wrong-label"}}}'
```

The Service now selects a label that the Web Pods do not have.

### Step 4 — Investigate the mismatch

Describe the Service:

```bash
kubectl describe service web-svc -n day50-lab
```

Check Pod labels:

```bash
kubectl get pods -n day50-lab --show-labels
```

Inspect EndpointSlices:

```bash
kubectl get endpointslices -n day50-lab
```

The Service should have no usable backend endpoints while its selector does not match any ready Pods.

### Step 5 — Repair the selector

Restore the expected selector:

```bash
kubectl patch service web-svc -n day50-lab \
  -p '{"spec":{"selector":{"app":"web-demo"}}}'
```

### Step 6 — Verify the repair

```bash
kubectl get endpointslices -n day50-lab
kubectl get endpoints -n day50-lab
kubectl describe service web-svc -n day50-lab
```

Expected result:

The Service should now have a backend endpoint corresponding to the ready Web Pod.

### Root Cause

The Service selector did not match the labels on the Web Pods.

### Fix

Restored the selector to:

```yaml
selector:
  app: web-demo
```

### Prevention

- Check Pod labels before creating a Service.
- Verify Service selectors.
- Investigate EndpointSlices whenever a Service has no backend endpoints.

---

## 7. Exercise D — Investigate PVC Pending

### Objective

Investigate why a PersistentVolumeClaim may remain in Pending status.

This is an investigation exercise. Do not create cloud disks or change cluster storage configuration.

### Step 1 — Inspect StorageClasses

```bash
kubectl get storageclass
```

This shows the available StorageClasses and their provisioners.

### Step 2 — Inspect PersistentVolumes

```bash
kubectl get pv
```

This shows the PersistentVolumes available in the cluster.

### Step 3 — Inspect PersistentVolumeClaims

```bash
kubectl get pvc -A
```

This displays PVCs across all namespaces.

### Two common reasons for PVC Pending

#### Reason 1 — No matching PersistentVolume

A PVC may request storage with requirements such as:

- Storage capacity.
- Access mode.
- StorageClass.
- Volume mode.

If no available PV matches the requirements, the PVC may remain Pending.

#### Reason 2 — Missing or non-working dynamic provisioner

A PVC may request dynamic provisioning, but the required provisioner may be missing or not functioning.

In that situation, Kubernetes cannot dynamically create the requested PersistentVolume.

### Root Cause Investigation

Check:

- Whether a suitable StorageClass exists.
- Whether the requested access mode is supported.
- Whether sufficient storage capacity is available.
- Whether the required provisioner is working.
- Whether an existing PV matches the PVC requirements.

### Important Safety Rule

This exercise requires investigation only.

Do not:

- Create cloud disks.
- Change existing StorageClasses.
- Delete PersistentVolumes.
- Modify existing PVCs.
- Change cluster storage configuration.

### Prevention

Verify storage requirements, available capacity, access modes, StorageClass configuration, and provisioner health before creating PVCs.

---

## 8. Exercise E — NetworkPolicy Investigation (Optional)

### Objective

Test communication between two Pods before and after applying an ingress NetworkPolicy.

This exercise should only be performed if the CNI plugin supports NetworkPolicy enforcement.

### Step 1 — Inspect network components

```bash
kubectl get pods -n kube-system -o wide
kubectl get daemonsets -A
minikube addons list
```

Confirm that the network implementation supports NetworkPolicy before continuing.

### Step 2 — Create two test Pods

Create a file named `network-test.yaml`.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: np-web
  namespace: day50-lab
  labels:
    app: np-web
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
  name: np-client
  namespace: day50-lab
  labels:
    app: np-client
spec:
  containers:
    - name: curl
      image: curlimages/curl:8.10.1
      command: ["sh", "-c", "sleep 36000"]
```

Apply the file:

```bash
kubectl apply -f network-test.yaml
```

Wait for the Pods:

```bash
kubectl wait --for=condition=Ready pod --all -n day50-lab --timeout=120s
```

### Step 3 — Test baseline connectivity

Get the Web Pod IP:

```bash
kubectl get pod np-web -n day50-lab -o wide
```

Test connectivity from the client:

```bash
kubectl exec -n day50-lab np-client -- curl -m 5 http://NP_WEB_POD_IP
```

Replace `NP_WEB_POD_IP` with the actual Pod IP.

If connectivity is working, the NGINX welcome page should be returned.

### Step 4 — Create an ingress-deny policy

Create `np-deny.yaml`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-np-web-ingress
  namespace: day50-lab
spec:
  podSelector:
    matchLabels:
      app: np-web
  policyTypes:
    - Ingress
```

Apply:

```bash
kubectl apply -f np-deny.yaml
```

### Step 5 — Test connectivity again

```bash
kubectl exec -n day50-lab np-client -- curl -m 5 http://NP_WEB_POD_IP
```

Expected result if the CNI enforces NetworkPolicy:

The request should fail or time out because no ingress sources have been allowed to access the selected Web Pod.

### Step 6 — Verify the policy

```bash
kubectl get networkpolicy -n day50-lab
kubectl describe networkpolicy deny-np-web-ingress -n day50-lab
```

### Important Notes

- NetworkPolicy is namespace-scoped.
- Ingress controls incoming traffic.
- The policy selects Pods using labels.
- CNI support is necessary for actual enforcement.
- Do not apply policies outside `day50-lab`.
- If traffic behavior does not change, investigate CNI support instead of assuming the policy is enforced.

---

## 9. Useful Troubleshooting Commands

### View Deployments, ReplicaSets, Pods and Services

```bash
kubectl get deploy,rs,pods,svc -n day50-lab
```

### View Pod details

```bash
kubectl describe pod POD_NAME -n day50-lab
```

### View current container logs

```bash
kubectl logs POD_NAME -n day50-lab
```

### View previous container logs

```bash
kubectl logs POD_NAME --previous -n day50-lab
```

### View namespace events

```bash
kubectl get events -n day50-lab
```

### View Pods with IP addresses

```bash
kubectl get pods -n day50-lab -o wide
```

### View Pod labels

```bash
kubectl get pods -n day50-lab --show-labels
```

### View Services and EndpointSlices

```bash
kubectl get svc,endpointslices -n day50-lab
```

---

## 10. Troubleshooting Summary

| Exercise | Symptom | Root Cause | Fix |
|---|---|---|---|
| A — ImagePullBackOff | Image cannot be pulled | Invalid image tag | Use `nginx:1.27` |
| B — CrashLoopBackOff | Container repeatedly exits | Process exits with code 1 | Use `sleep 36000` |
| C — Service selector | No usable Service endpoints | Selector does not match Pod labels | Restore `app=web-demo` |
| D — PVC Pending | PVC cannot bind | No matching PV or provisioner problem | Investigate storage configuration |
| E — NetworkPolicy | Traffic behavior does not change | CNI may not enforce NetworkPolicy | Verify CNI support |

---

## 11. Deliverables

For each exercise, document the following:

1. Symptom.
2. Diagnostic command and output.
3. Root cause.
4. Fix.
5. Verification.
6. One prevention tip.
7. YAML files or commands used.

### Suggested Troubleshooting Record

| Field | Details |
|---|---|
| Exercise | Name of the exercise |
| Symptom | What went wrong? |
| Diagnostic command | Which command was used? |
| Evidence | What did the output show? |
| Root cause | Why did it happen? |
| Fix | What change repaired it? |
| Verification | How was recovery confirmed? |
| Prevention | How can it be avoided? |

---

## 12. Screenshots

The PDF allows a maximum of five screenshots.

Recommended screenshots:

1. ImagePullBackOff and Events before repair.
2. CrashLoopBackOff logs or Events.
3. Service selector mismatch and empty EndpointSlices.
4. Successful rollout and Ready Pods after fixes.
5. Concise root-cause and verification summary.

Avoid including unrelated namespaces or sensitive cluster information.

---

## 13. Interview Questions and Answers

### Q1. What is the difference between ImagePullBackOff and CrashLoopBackOff?

**ImagePullBackOff:** Kubernetes cannot successfully pull the requested container image.

**CrashLoopBackOff:** The container repeatedly starts and exits or fails, causing Kubernetes to restart it with increasing backoff delays.

### Q2. How do you investigate a Pending Pod?

Use:

```bash
kubectl describe pod POD_NAME -n day50-lab
kubectl get events -n day50-lab
```

Inspect scheduling conditions, resource requirements, storage requirements, and related events.

### Q3. Why can a Service have no endpoints?

A Service may have no endpoints because:

- Its selector does not match any Pods.
- Matching Pods are not Ready.
- The relevant workload is unavailable.

### Q4. How do you view logs from a previous crashed container?

Use:

```bash
kubectl logs POD_NAME --previous -n day50-lab
```

This displays logs from the previous terminated container instance when available.

### Q5. Why should you inspect events before changing resources?

Events provide evidence about what happened to a Kubernetes resource.

Inspecting them helps identify the root cause and avoids unnecessary or unsafe configuration changes.

---

## 14. Cleanup

After completing all exercises, remove the dedicated Day50 namespace.

First verify the current context:

```bash
kubectl config current-context
kubectl get namespace day50-lab
```

Delete only the Day50 namespace:

```bash
kubectl delete namespace day50-lab
```

Verify removal:

```bash
kubectl get namespace day50-lab
```

Expected result:

```text
Error from server (NotFound): namespaces "day50-lab" not found
```

Restore the default namespace in the current context:

```bash
kubectl config set-context --current --namespace=default
```

**Safety:** Do not delete other namespaces, shared cluster components, CNI plugins, StorageClasses, or cluster-wide resources.

No AWS resources are required for Day50.

---

## 15. Day50 Completion Checklist

- [ ] Verified Minikube and Kubernetes context.
- [ ] Created the `day50-lab` namespace.
- [ ] Reproduced ImagePullBackOff.
- [ ] Fixed ImagePullBackOff using a valid image.
- [ ] Reproduced CrashLoopBackOff.
- [ ] Repaired the crashing container command.
- [ ] Reproduced the Service selector mismatch.
- [ ] Restored the correct Service selector.
- [ ] Investigated PVC Pending causes.
- [ ] Investigated NetworkPolicy behavior if CNI supports enforcement.
- [ ] Documented symptoms, root causes, fixes, and verification.
- [ ] Captured relevant screenshots.
- [ ] Cleaned up only the Day50 namespace.

---

## Day50 Summary

Day50 teaches practical Kubernetes troubleshooting through controlled failures.

The main lessons are:

1. ImagePullBackOff is commonly caused by an incorrect or unavailable image.
2. CrashLoopBackOff occurs when a container repeatedly exits or fails.
3. A Service requires matching Pod selectors to discover its backend Pods.
4. PVC Pending can result from storage matching or provisioning problems.
5. NetworkPolicy enforcement depends on CNI support.
6. Kubernetes troubleshooting should always be based on evidence.

**Key takeaway:** A good DevOps engineer does not randomly change Kubernetes resources. They inspect, understand the root cause, make the smallest safe fix, and verify recovery.
