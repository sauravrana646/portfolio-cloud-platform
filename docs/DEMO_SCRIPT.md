# Demo script (5–10 minutes)

1. **Story (30s):** `portfolio-secure-cicd` builds, signs, and publishes a multi-arch
   image; this pack pins the digest and verifies with Infisical + Kyverno.
2. Show the pin in
   `helm-values/applications/demo-app/environments/dev/images.yaml`
   (currently `v0.2.0` / multi-arch digest).
3. **Compose ($0):** `make up` → `curl -s http://127.0.0.1:8080/healthz`.
4. (Optional) `make verify-image` with Infisical — signature + SPDX OK.
5. **OrbStack + Argo** (preferred local cluster path): follow
   [`LOCAL_K8S_ORBSTACK.md`](LOCAL_K8S_ORBSTACK.md) — Universal Auth, bootstrap root,
   `root-dev`, then:
   ```bash
   kubectl -n demo-app-dev port-forward svc/demo-app-api 8080:80
   curl -s http://127.0.0.1:8080/healthz
   ```
6. Show Kyverno ClusterPolicies and deny a bad Pod in `demo-app-dev`
   (tag-only / bogus digest). Positive proof: Pod annotation
   `kyverno.io/verify-images` after `rollout restart`.
7. Open **Policy Reporter UI**:
   `kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8082:8080`
   → http://127.0.0.1:8082
8. Mention per-env Argo roots (`root-bootstrap` / `root-dev` / …); promotion =
   digest bump PR under `helm-values/.../images.yaml`.
9. (Optional) Teleport JIT: `tsh login` → `tsh kube login` (`docs/JIT_TELEPORT.md`).
10. Mention EKS via Terraform is opt-in; tear down Compose with `make down`.
