# JIT access with Teleport (not AWS JIT)

This pack uses **Teleport** for short-lived Kubernetes access.  
**Out of scope:** AWS IAM Identity Center, EKS access entries as the JIT story, and SSM Session Manager as the primary access path.

## Why Teleport here

- Time-bound `kubectl` via `tsh` (certificates, not long-lived kubeconfigs)
- Works the same on OrbStack/kind and EKS
- OSS agent chart fits App-of-Apps; optional Teleport Cloud free/team for the control plane (no AWS SSO product)

## Pieces

| Piece | Where |
|-------|--------|
| Teleport **proxy / auth** | Teleport Cloud **or** self-hosted `teleport-cluster` (not required in-repo by default) |
| Teleport **kube agent** | Argo app `platform-teleport-agent` → Helm `teleport-kube-agent` 18.10.3 |
| Values | `helm-values/bootstrap-layer/teleport-kube-agent/values.yaml` |
| Join token Secret | `teleport/teleport-kube-agent-join-token` (created out-of-band) |

## Bootstrap (once)

1. Have a Teleport cluster (Cloud signup or self-host).
2. Create a kube join token:
   ```bash
   tctl tokens add --type=kube --ttl=1h
   ```
3. On the target Kubernetes cluster:
   ```bash
   kubectl create namespace teleport --dry-run=client -o yaml | kubectl apply -f -
   kubectl -n teleport create secret generic teleport-kube-agent-join-token \
     --from-literal=auth-token='<token>'
   ```
4. Edit `helm-values/bootstrap-layer/teleport-kube-agent/values.yaml`
   (keys under `teleport-kube-agent:`):
   - `proxyAddr` → your Teleport proxy (`example.teleport.sh:443`)
   - `kubeClusterName` → e.g. `portfolio-cloud-platform` or `orbstack-demo`
5. Sync Argo app `platform-teleport-agent` (manual sync by design until configured).

## Operator demo flow

```bash
tsh login --proxy=example.teleport.sh:443
tsh kube login portfolio-cloud-platform
kubectl -n demo-app-dev get pods   # short-lived cert via Teleport
tsh status                     # show expiry — the JIT talking point
```

Map Teleport roles → Kubernetes groups in Teleport RBAC (viewer vs admin). Do **not** hand out permanent `system:masters` kubeconfigs for demos.

## Cost notes

| Option | Cost |
|--------|------|
| Teleport kube-agent on existing nodes | Compute already paid (local $0 / EKS node) |
| Teleport Cloud (small demo) | Free/team tier often enough for portfolio |
| Self-hosted `teleport-cluster` | Extra pods/CPU on the cluster; document if you add it later |

AWS IAM Identity Center / SSM JIT is intentionally **not** used.
