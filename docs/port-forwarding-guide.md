# Port Forwarding & Access Guide

This document lists all internal cluster services, their default ports, recommended host forwarding ports, and access instructions for both the **Rancher Desktop GUI** and the **`kubectl` CLI**.

---

## 📌 Service Port Forwarding Matrix

| Namespace | Kubernetes Service | Service Port | Protocol | Recommended Host Port | Browser URL | Default Credentials | Purpose / Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`monitoring`** | `prometheus-grafana` | `80/TCP` (`http-web`) | HTTP | **`3000`** | [http://localhost:3000](http://localhost:3000) | `admin` / `prom-operator` | Grafana Web Dashboard & Alerting UI |
| **`monitoring`** | `prometheus-kube-prometheus-prometheus` | `9090/TCP` (`http-web`) | HTTP | **`9090`** | [http://localhost:9090](http://localhost:9090) | *(None)* | Prometheus Metrics & PromQL Query UI |
| **`argocd`** | `argocd-server` | `443/TCP` (`https`) | HTTPS | **`8080`** | [https://localhost:8080](https://localhost:8080) | `admin` / *(Secret password)* | Argo CD GitOps Console |
| **`(Optional) scaler-app`** | `scaler-service` | `80/TCP` (`http`) | HTTP | **`8081`** | [http://localhost:8081](http://localhost:8081) | *(None)* | Scaler App (`/healthcheck`) Load Balancer |
| **`monitoring`** | `prometheus-kube-prometheus-alertmanager` | `9093/TCP` (`http-web`) | HTTP | **`9093`** | [http://localhost:9093](http://localhost:9093) | *(None)* | Alertmanager Web UI & Active Alerts |

> [!WARNING]
> **Do NOT forward `reloader-web`:** Under `monitoring` ➔ `prometheus-kube-prometheus-prometheus`, never forward `reloader-web` to port `8080`. It is an internal reloader sidecar and will block your host port `8080` from opening the Argo CD web console! Always forward `http-web` to `9090` for Prometheus.

---

## 🖥️ How to Forward via Rancher Desktop GUI

1. Open the **Rancher Desktop** window on your desktop.
2. In the left navigation bar, click on **Port Forwarding**.
3. Locate the service row:
   - **For Grafana:** Find namespace `monitoring` ➔ service `prometheus-grafana` ➔ port `http-web` ➔ click **Forward** ➔ set port **`3000`**.
   - **For Prometheus:** Find namespace `monitoring` ➔ service `prometheus-kube-prometheus-prometheus` ➔ port `http-web` ➔ click **Forward** ➔ set port **`9090`**.
   - **For Argo CD:** Find namespace `argocd` ➔ service `argocd-server` ➔ port `https` ➔ click **Forward** ➔ set port **`8080`**.
   - **For App Service:** Find namespace `scaler-app` ➔ service `scaler-service` ➔ port `http` ➔ click **Forward** ➔ set port **`8081`**.
4. The button changes to **Cancel**, confirming the port is forwarded to `localhost`.

---

## ⌨️ How to Forward via Terminal (`kubectl`)

If you prefer running port forwards via terminal commands:

```bash
# 1. Grafana (Port 3000)
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80

# 2. Prometheus (Port 9090)
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090

# 3. Alertmanager (Port 9093)
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093

# 4. Argo CD (Port 8080)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 5. Scaler App Service (Port 8081)
kubectl port-forward svc/scaler-service -n scaler-app 8081:80
```

---

## 🔑 Argo CD Password Retrieval

To retrieve the Argo CD `admin` password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```
