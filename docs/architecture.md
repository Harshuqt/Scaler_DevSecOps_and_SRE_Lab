# Architecture & System Topology

This document details the end-to-end DevSecOps and SRE architecture implemented for the Scaler Assessment.

---

## 🏗️ End-to-End System Architecture

```mermaid
flowchart TD
    subgraph Developer_Workflow ["1. Developer Workflow & Version Control"]
        Dev["Developer (Local Machine)"] -->|Create Feature Branch| GitBranch["Git Branch (e.g. fix/...)"]
        GitBranch -->|Open Pull Request| PR["GitHub Pull Request"]
    end

    subgraph CI_Security_Gates ["2. Multi-Stage CI Pipeline (pr-checks.yaml)"]
        PR --> Lint["1. Flake8 Linting"]
        Lint --> UnitTest["2. Pytest Unit Tests (6/6 Passed)"]
        UnitTest --> SAST["3. Bandit SAST (Ignore B104)"]
        SAST --> SecretScan["4. Gitleaks Secret Detection"]
        SecretScan --> DockerBuild["5. Docker Build (Alpine 3.13)"]
        DockerBuild --> Trivy["6. Trivy Vulnerability Scan"]
        Trivy --> Gatekeeper["7. Vulnerability Script (CVSS Gate)"]
    end

    subgraph CD_Release_Pipeline ["3. Release & Matrix Pipeline (release.yaml)"]
        Gatekeeper -->|PR Approved & Merged| Main["main branch"]
        Main --> ReleaseAction["Release Workflow Trigger"]
        ReleaseAction --> MatrixBuild["Build Matrix: [v1, v2, v3]"]
        MatrixBuild --> GHCR["Push to GitHub Container Registry (GHCR)"]
        MatrixBuild --> AutoPR["Bot Creates chore/gitops-update PR"]
        AutoPR -->|Merged| GitOpsSync["Updated Image Tags in k8s/"]
    end

    subgraph GitOps_Engine ["4. Argo CD GitOps Engine"]
        GitOpsSync --> ArgoCD["Argo CD Application Controller"]
        ArgoCD -->|Reconcile State & Self-Heal (3s)| K8sCluster["Kubernetes Cluster (K3s)"]
    end

    subgraph Kubernetes_Runtime ["5. Kubernetes Enterprise Footprint (scaler-app)"]
        K8sCluster --> NS["Namespace: scaler-app"]
        NS --> Quota["ResourceQuota (600m CPU, 1200Mi RAM)"]
        NS --> NetPol["NetworkPolicy (Ingress 8080, Egress DNS)"]
        NS --> RBAC["RBAC: ServiceAccount + Role + Binding"]
        NS --> ConfigSecret["ConfigMap + Secret"]
        NS --> Svc["Shared Service: scaler-service (Port 80)"]

        Svc --> Dep1["Deployment v1 (Pod)"]
        Svc --> Dep2["Deployment v2 (Pod)"]
        Svc --> Dep3["Deployment v3 (Pod)"]

        Dep1 -.->|400Mi Limit Hit| OOM1["OOMKilled (Exit 137)"]
        Dep2 -.->|400Mi Limit Hit| OOM2["OOMKilled (Exit 137)"]
        Dep3 -.->|400Mi Limit Hit| OOM3["OOMKilled (Exit 137)"]
    end

    subgraph Observability_Stack ["6. Full Observability & Alerting Stack (monitoring)"]
        K8sCluster --> PromStack["kube-prometheus-stack (Helm)"]
        PromStack --> KubeStateMetrics["Kube-State-Metrics (Pod Restarts & OOMKilled)"]
        PromStack --> NodeExporter["Node Exporter (CPU, RAM, Disk)"]
        PromStack --> PromServer["Prometheus Server (TSDB & Rule Engine)"]
        PromServer --> Alertmanager["Alertmanager"]
        Alertmanager --> AlertsFiring["Alerts: ScalerAppPodUnhealthy & ScalerAppContainerOOMKilled"]

        K8sCluster --> LokiStack["Loki + Promtail (Centralized Logging)"]
        LokiStack --> PromtailDaemon["Promtail (Tail /var/log/pods)"]
        PromtailDaemon --> LokiServer["Loki Server (Log Ingestion)"]

        PromServer --> Grafana["Grafana Web UI (Port 3000)"]
        LokiServer --> Grafana
        Grafana --> Dashboard["Custom SRE Dashboard (scaler-sre-overview)"]
    end
```

---

## 🛡️ Security Posture & Hardening Summary

1. **Base Image:** `python:3.13-alpine` (Minimal attack surface, zero high/critical vulnerabilities).
2. **Non-Root Execution:** Numeric UID `1000` (`runAsUser: 1000`, `runAsNonRoot: true`).
3. **Defense in Depth in CI:** Flake8, Pytest, Bandit, Gitleaks, Docker Build, Trivy, and custom CVSS threshold gatekeeper script.
4. **Network Isolation:** Namespace-level `NetworkPolicy` blocking unauthorized egress while permitting internal cluster DNS (`kube-dns`).
5. **Node Protection:** Pod memory limits strictly capped at `400Mi` so runaway memory leaks are terminated via Linux OOM killer before host instability occurs.
