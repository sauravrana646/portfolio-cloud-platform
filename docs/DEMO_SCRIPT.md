# Demo script (5–10 minutes)

1. **Story (30s):** secure-cicd builds & signs; this pack deploys & verifies.
2. Show pinned digest in `deploy/environments/prod/images.yaml`.
3. `docker compose up -d` → `curl /healthz` and `/`.
4. (Optional) `make verify-image` with Infisical — signature + SPDX OK.
5. `make cluster-deploy` → port-forward → same healthz.
6. Show Kyverno policy `require-signed-images` / `require-digest`.
7. Mention Argo App-of-Apps and env overlays; promotion = digest bump PR.
8. (Optional) Teleport JIT: `tsh login` → `tsh kube login` → show cert expiry (`docs/JIT_TELEPORT.md`).
9. Mention EKS via Terraform is opt-in, no NAT by default, destroy after.
10. `make cluster-down && make down`.
