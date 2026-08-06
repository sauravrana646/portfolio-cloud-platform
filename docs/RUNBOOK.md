# Runbook — portfolio-cloud-platform

## Health

| Check | Command |
|-------|---------|
| Compose API | `curl -s http://127.0.0.1:8080/healthz` |
| Compose work | `curl -s http://127.0.0.1:8080/work` |
| Compose metrics | `curl -s http://127.0.0.1:8080/metrics \| head` |
| Cluster context | `kubectl config current-context` (expect `orbstack` or your local cluster) |
| Cluster pods | `kubectl -n demo get pods` |
| Cluster forward | `kubectl -n demo port-forward svc/demo-api 8080:80` |

## Common failures

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| ImagePullBackOff | Image not in cluster store | Rebuild with `make cluster-deploy` (OrbStack shares Docker images) |
| `/work` 503 | Redis unreachable | Ensure compose Redis is up, or omit `REDIS_URL` in cluster |
| Helm timeout | Context wrong / API slow | `kubectl config use-context orbstack` then retry |
| Trivy CI fail | New CRITICAL in base image | `apt-get upgrade` in Dockerfile; re-pin base |

## Rollback

- **Compose:** `docker compose down -v` then redeploy previous tag
- **Helm:** `helm rollback demo 1 -n demo` or `make cluster-down`
- **Git:** revert the bad commit; CI rebuilds the image

## Teardown

```bash
make down            # compose
make cluster-down    # helm release + demo namespace
```
