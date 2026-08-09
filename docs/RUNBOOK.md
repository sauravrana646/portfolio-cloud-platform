# Runbook — portfolio-cloud-platform

## Health

| Check | Command |
|-------|---------|
| Compose API | `curl -s http://127.0.0.1:8080/healthz` |
| Compose root | `curl -s http://127.0.0.1:8080/` |
| Cosign verify (laptop) | `make verify-image` (Infisical + cosign) |
| Cosign key in cluster | `kubectl -n platform-system get secret cosign-public-key -o jsonpath='{.data.cosign\.pub}' \| base64 -d \| head` |
| ClusterPolicies | `kubectl get clusterpolicy` |
| Policy Reporter UI | `kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8082:8080` → http://127.0.0.1:8082 |
| demo-app (dev) | `kubectl -n demo-app-dev get pods,deploy,svc` |
| demo-app forward | `kubectl -n demo-app-dev port-forward svc/demo-app-api 8080:80` |
| Grafana | `kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80` |
| Teleport JIT | `tsh login` → `tsh kube login <kubeClusterName>` (see `docs/JIT_TELEPORT.md`) |
| Cluster context | `kubectl config current-context` |

## Verify Kyverno allowed a signed digest

Do **not** delete the Argo Application. Admission runs on **new Pod creates**.

```bash
# Positive: re-admit the real app
kubectl -n demo-app-dev rollout restart deploy/demo-app-api
kubectl -n demo-app-dev rollout status deploy/demo-app-api
kubectl -n demo-app-dev get pod -l app=demo-app-api \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{.metadata.annotations.kyverno\.io/verify-images}{"\n"}{end}'

# Negative: must be DENIED by webhook
kubectl -n demo-app-dev run bad-tag --restart=Never \
  --image=ghcr.io/sauravrana646/portfolio-secure-cicd:v0.2.0
kubectl -n demo-app-dev run bad-sig --restart=Never \
  --image=ghcr.io/sauravrana646/portfolio-secure-cicd@sha256:0000000000000000000000000000000000000000000000000000000000000001
kubectl -n demo-app-dev delete pod bad-tag bad-sig --ignore-not-found
```

Digest + cosign policies match `demo-app-dev`, `demo-app-uat`, `demo-app-prod`
(and legacy `demo`). SBOM attestation remains Audit on uat/prod only.

## Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| ImagePullBackOff `no matching manifest for linux/arm64` | Old single-arch digest (e.g. `v0.1.0`) | Pin multi-arch release (`v0.2.0+`); bump `images.yaml` |
| ImagePullBackOff (other) | GHCR/network | Check digest; `docker pull` the IMAGE_REF |
| gunicorn `No usable temporary directory` | `readOnlyRootFilesystem` without `/tmp` | Chart must mount `emptyDir` at `/tmp` + `TMPDIR` (fixed on `main`) |
| Kyverno block | Unsigned / tag-only image | Pin `@sha256:…`; ensure Infisical public key Secret exists |
| `validate-policy.kyverno.svc` rejects SBOM policy | `mutateDigest` default with Audit | Policy must set `mutateDigest: false` (fixed on `main`) |
| AppSet `duplicate name:` (empty) | `templatePatch` wiped `metadata.name` | On `main`: only emit `metadata` when setting finalizers; hard-refresh AppSet |
| AppSet duplicate names (non-empty) | Greedy `files:` globs | Use explicit paths in ApplicationSet (no `*/app.yaml`) |
| Argo `DeadlineExceeded` / `RST_STREAM CANCEL` | repo-server timeout | Hard refresh; restart `argocd-repo-server`; retry sync |
| `make verify-image` fails | No Infisical identity / key | Export `cosign_public_key` or configure Infisical CLI |
| InfisicalSecret reverts to kubernetesAuth on OrbStack | Argo selfHeal on git CR | Pause `bootstrap-infisical-secrets` sync; re-apply Universal Auth overlay (`docs/LOCAL_K8S_ORBSTACK.md` §6) |
| Teleport agent CrashLoop / Missing | Missing join token / bad `proxyAddr` | Create Secret + fix values; manual sync (`docs/JIT_TELEPORT.md`) |
| `/metrics` empty | Upstream has no metrics yet | Use `/healthz` probes |
| Helm timeout | Wrong context | `kubectl config use-context …` then retry |
| EKS bill surprise | Cluster left up / NAT added | `terraform destroy`; keep `eks_public_nodes=true` |

## Rollback

- **Compose:** `docker compose down -v` then redeploy previous digest in compose / `IMAGE_REF`
- **Helm (Kind bootstrap):** `helm rollback` / `make bootstrap-down`
- **GitOps:** revert the `images.yaml` digest PR; Argo syncs
- **EKS:** `terraform destroy -var='deploy_target=eks'`

## Meter is running (EKS)

If you applied EKS: control plane + node are billed until destroy.
Checklist: [ ] demo done [ ] `terraform destroy` [ ] confirm no NAT/ALB left

## Teardown

```bash
make down                 # compose
make bootstrap-down       # Kind/Helm local bootstrap (if used)
# OrbStack GitOps: delete platform-root-dev / charts-dev (and bootstrap roots if desired)
# cd infra/terraform && terraform destroy -var='deploy_target=eks'
```
