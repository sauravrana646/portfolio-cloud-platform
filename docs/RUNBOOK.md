# Runbook — portfolio-cloud-platform

## Health

| Check | Command |
|-------|---------|
| Compose API | `curl -s http://127.0.0.1:8080/healthz` |
| Compose root | `curl -s http://127.0.0.1:8080/` |
| Cosign verify | `make verify-image` (Infisical + cosign) |
| Cluster context | `kubectl config current-context` |
| Cluster pods | `kubectl -n demo get pods` |
| Cluster forward | `kubectl -n demo port-forward svc/demo-api 8080:80` |

## Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| ImagePullBackOff | GHCR/network | Check digest; `docker pull` the IMAGE_REF |
| Kyverno block | Unsigned / tag-only image | Pin digest; ensure Infisical public key Secret exists |
| `make verify-image` fails | No Infisical identity / key | Export `cosign_public_key` or configure Infisical CLI/OIDC |
| `/metrics` empty | Upstream has no metrics yet | Use `/healthz` probes; see monitoring notes |
| Helm timeout | Wrong context | `kubectl config use-context …` then retry |
| EKS bill surprise | Cluster left up / NAT added | `terraform destroy`; keep `eks_public_nodes=true` |

## Rollback

- **Compose:** `docker compose down -v` then redeploy previous digest in `.env` / compose
- **Helm:** `helm rollback demo 1 -n demo` or `make cluster-down`
- **GitOps:** revert the `images.yaml` digest PR; Argo syncs
- **EKS:** `terraform destroy -var='deploy_target=eks'`

## Meter is running (EKS)

If you applied EKS: control plane + node are billed until destroy.
Checklist: [ ] demo done [ ] `terraform destroy` [ ] confirm no NAT/ALB left

## Teardown

```bash
make down            # compose
make cluster-down    # helm release + demo namespace
# cd infra/terraform && terraform destroy -var='deploy_target=eks'
```
