# Complete Environment Reproduction & Demo Runbook

This runbook provides step-by-step instructions to reproduce and demonstrate the complete Scaler DevSecOps & SRE platform from scratch on Linux / macOS using Rancher Desktop K3s.

---

## 📋 Prerequisites

- **Host Machine:** Linux (Ubuntu/Debian/Mint) or macOS with at least 8 GB RAM (16 GB recommended).
- **Rancher Desktop:** Installed with K3s Kubernetes engine enabled.
  - Set VM memory to at least **`6 GB`** (Preferences ➔ Virtual Machine ➔ 6 GB RAM, 4 CPUs).
- **CLI Tools:** `git`, `kubectl`, `helm`, `docker`.

---

## 🚀 Step 1: Clone Repository & Setup Rancher Desktop

```bash
git clone git@github.com:Harshuqt/Scaler_DevSecOps_and_SRE_Lab.git
cd Scaler_DevSecOps_and_SRE_Lab
```

Ensure `kubectl` points to the Rancher Desktop context:
```bash
kubectl config use-context rancher-desktop
kubectl get nodes
```

---

## 🚀 Step 2: Deploy Argo CD & Application Footprint

```bash
# 1. Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.6.1/manifests/install.yaml

# 2. Retrieve Initial Admin Password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# 3. Apply the Argo CD Application manifest
kubectl apply -f argocd/application.yaml
```

Argo CD will automatically sync all manifests inside `k8s/` into the `scaler-app` namespace.

---

## 🚀 Step 3: Deploy Monitoring Stack (Prometheus + Grafana + Loki)

```bash
# 1. Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 2. Install kube-prometheus-stack
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/prometheus-values.yaml

# 3. Install Loki & Promtail
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --values monitoring/loki-values.yaml

# 4. Apply Dashboard, Loki DataSource, and Alerting Rules
kubectl apply -f monitoring/grafana-dashboard-scaler.yaml
kubectl apply -f monitoring/grafana-datasource-loki.yaml
kubectl apply -f monitoring/prometheus-alerts-scaler.yaml
```

---

## 🚀 Step 4: Port Forwarding (Rancher Desktop GUI or CLI)

Refer to [`docs/port-forwarding-guide.md`](file:///home/harshal/Desktop/Backup/Git/Scaler_DevSecOps_and_SRE_Lab/docs/port-forwarding-guide.md) for full details.

```bash
# Grafana (Dashboards)
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80 &

# Prometheus (Metrics & PromQL)
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090 &

# Argo CD (GitOps Console)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Scaler App Load Balancer
kubectl port-forward svc/scaler-service -n scaler-app 8081:80 &
```

---

## 🚀 Step 5: Demo & Verification Walkthrough

1. **Verify GitOps in Argo CD:**
   - Open [https://localhost:8080](https://localhost:8080) (User: `admin`).
   - Observe `scaler-application` managing Deployments `v1`, `v2`, `v3`, Quotas, and NetworkPolicies.
2. **Verify Shared Load Balancer:**
   - Run: `curl http://localhost:8081/healthcheck`
   - Observe responses rotating evenly across versions (`{"status": "healthy", "version": "v1"}`, `"v2"`, `"v3"`).
3. **Verify OOMKilled & Self-Healing:**
   - Check pod terminations: `kubectl get pods -n scaler-app`
   - Notice pods hit the `400Mi` memory limit after ~90 seconds and exit with code 137 (`OOMKilled`).
   - Kubernetes immediately brings up a fresh replacement pod.
4. **Verify SRE Dashboard in Grafana:**
   - Open [http://localhost:3000](http://localhost:3000) (User: `admin`, Password: `prom-operator`).
   - Go to Dashboards ➔ **`Scaler SRE Assessment - Cluster & App Health`**.
   - Show live restart counters, active OOMKilled indicators, and host memory usage.
5. **Verify Centralized Logs in Grafana Explore:**
   - Go to Explore ➔ Select **`Loki`** ➔ Query: `{namespace="scaler-app"}`.
   - Show stdout log streams capturing memory increments.
6. **Verify Active Alerting Rules:**
   - Open [http://localhost:9090/alerts](http://localhost:9090/alerts).
   - Show `ScalerAppContainerOOMKilled` and `ScalerAppPodUnhealthy` firing.
