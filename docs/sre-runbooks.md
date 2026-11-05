# SRE Incident Response Runbooks & Playbooks

This guide provides operational runbooks for SREs handling production incidents with the `scaler-app` service.

---

## 📘 Runbook 1: OOMKilled Alert (`ScalerAppContainerOOMKilled`)

### Alert Metadata
- **Alert Name:** `ScalerAppContainerOOMKilled`
- **Severity:** `Critical`
- **Trigger Query:** `kube_pod_container_status_last_terminated_reason{namespace="scaler-app", reason="OOMKilled"} == 1`

### Symptoms
1. Prometheus alerts firing in Alertmanager and Grafana.
2. Pod restart count incrementing rapidly (`kubectl get pods -n scaler-app`).
3. Pod status periodically changes to `CrashLoopBackOff` or `OOMKilled`.

### Diagnostic Steps
1. **Identify the affected pod and termination reason:**
   ```bash
   kubectl get pods -n scaler-app
   kubectl describe pod -n scaler-app <pod-name> | grep -A 5 "Last State:"
   ```
   *Expected output: `Reason: OOMKilled`, `Exit Code: 137`.*
2. **Review application memory progression prior to termination:**
   ```bash
   kubectl logs -n scaler-app <pod-name> --previous --tail=25
   ```
   *Look for memory increments reaching ~376MB–400MB.*
3. **Inspect memory graph in Grafana:**
   Open the **Scaler SRE Dashboard** (`http://localhost:3000/d/scaler-sre-overview/scaler-sre-assessment-cluster-and-app-health`) to verify memory trend.

### Remediation & Mitigation
- **Short-term:** Kubernetes automatically restarts the pod within seconds. The shared `scaler-service` load balancer routes incoming traffic to healthy pods (`v1`, `v2`, or `v3`), ensuring zero downtime for callers.
- **Root Cause Resolution:** Engage application developers to inspect `app/app.py` for uncontrolled data structure accumulation (e.g. infinite lists, caches without eviction policies).

---

## 📘 Runbook 2: Pod Healthcheck Failure (`ScalerAppPodUnhealthy`)

### Alert Metadata
- **Alert Name:** `ScalerAppPodUnhealthy`
- **Severity:** `Critical`
- **Trigger Query:** `kube_pod_status_ready{namespace="scaler-app", condition="true"} == 0` for `> 30s`

### Symptoms
1. HTTP probes failing on port 8080 (`/healthcheck`).
2. Pod marked as `0/1 Ready` in Kubernetes.

### Diagnostic Steps
1. **Check probe failure events:**
   ```bash
   kubectl describe pod -n scaler-app <pod-name> | grep -i probe
   ```
2. **Verify container responsiveness inside the cluster:**
   ```bash
   kubectl exec -n scaler-app <pod-name> -- curl -s http://localhost:8080/healthcheck
   ```
3. **Query centralized logs in Grafana Explore:**
   Open Grafana Explore ➔ Data Source: `Loki` ➔ Run:
   ```logql
   {namespace="scaler-app", pod="<pod-name>"}
   ```

### Remediation
- If the pod is hung during startup, inspect initContainer preflight status:
  ```bash
  kubectl logs -n scaler-app <pod-name> -c preflight-check
  ```
- If the pod is in backoff, force a restart:
  ```bash
  kubectl rollout restart deployment <deployment-name> -n scaler-app
  ```

---

## 📘 Runbook 3: Argo CD Drift & Self-Healing Verification

### Overview
Argo CD is configured with automated sync and self-healing:
```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

### Verification Procedure
1. **Test self-healing by deleting a deployment manually:**
   ```bash
   kubectl delete deployment scaler-app-v1 -n scaler-app
   ```
2. **Observe Argo CD detection and restoration:**
   ```bash
   # Argo CD will detect OutOfSync drift and recreate the deployment within ~3-5 seconds!
   kubectl get deployments -n scaler-app
   ```
3. **Check Argo CD sync status:**
   ```bash
   kubectl get app -n argocd scaler-application
   ```
   *Status will remain `Synced`.*
