# Local Kubernetes on OrbStack (end-to-end)

GitOps path for a Mac laptop with **OrbStack Kubernetes** and **Argo CD already
installed**. Deploys bootstrap (Kyverno, monitoring, policies, Infisical operator)
plus one workload env (`dev` by default).

Do **not** run `make bootstrap-up` on this cluster — that Helm-installs the same
charts and will fight Argo.

For Compose-only ($0, no cluster): see [`local/README.md`](../local/README.md).  
For Kind without Argo: see [`local/bootstrap/README.md`](../local/bootstrap/README.md).

---

## What you will have

| Piece | How |
|-------|-----|
| Argo CD | Pre-installed in OrbStack (you) |
| Platform | `argocd/root-bootstrap.yaml` |
| Workloads | `argocd/root-dev.yaml` (or uat/prod) |
| Cosign public key | Infisical **Universal Auth** → K8s Secret (OrbStack-friendly) |

**Why Universal Auth?** Infisical Cloud cannot call OrbStack’s TokenReview API, so
**Kubernetes Auth does not work** for local OrbStack. Use Universal Auth
(Client ID + Client Secret) here; use Kubernetes Auth later on EKS.

---

## 0. Prerequisites

- [OrbStack](https://orbstack.dev/) with **Kubernetes enabled**
- Argo CD installed in the cluster (ApplicationSet controller enabled)
- Tools: `kubectl`, `git`, optional `helm` / Infisical CLI
- This repo reachable by Argo: `https://github.com/sauravrana646/portfolio-cloud-platform.git`  
  (public, or credentials configured in Argo)
- Cosign **public** key available (same material as Infisical `/cosign`, or a PEM file)

```bash
kubectl config use-context orbstack
kubectl -n argocd get pods
# Expect argocd-server, repo-server, application-controller, applicationset-controller (names vary by install)
```

---

## 1. Checkout `main`

```bash
git clone https://github.com/sauravrana646/portfolio-cloud-platform.git
cd portfolio-cloud-platform
git checkout main && git pull
```

---

## 2. Remove old monolithic App-of-Apps (if present)

Only if you previously applied the single `root.yaml` / ApplicationSet `charts`:

```bash
kubectl -n argocd delete application platform-root --ignore-not-found
kubectl -n argocd delete applicationset charts --ignore-not-found
```

If `charts-bootstrap` shows **“contains applications with duplicate name”**
(especially `duplicate name:` with nothing after the colon):

1. Ensure you are on current `main`:
   - **Explicit** `files:` paths (no `*/app.yaml` globs — greedy globs duplicate apps).
   - AppSet `templatePatch` only emits `metadata` when setting finalizers
     (empty `metadata:` used to wipe `metadata.name` → Applications named `""`).
2. Clean leftovers, then hard-refresh:

```bash
kubectl -n argocd get applicationset
kubectl -n argocd get applicationset charts-bootstrap -o yaml | grep -A20 'files:'

# Must NOT show a glob like '*/app.yaml' — only concrete paths
kubectl -n argocd delete applicationset charts --ignore-not-found
kubectl -n argocd delete application platform-root --ignore-not-found

# Recreate cleanly: delete AppSet children then refresh
kubectl -n argocd delete application -l app.kubernetes.io/managed-by=charts-bootstrap-applicationset --ignore-not-found
kubectl -n argocd delete application -l app.kubernetes.io/managed-by=charts-applicationset --ignore-not-found

kubectl -n argocd annotate applicationset charts-bootstrap \
  argocd.argoproj.io/application-set-refresh=true --overwrite
# UI: platform-root-bootstrap → Hard Refresh + Sync
```

---

## 3. Infisical — secret + Universal Auth machine identity

### 3a. Store the cosign public key

1. Open [Infisical](https://app.infisical.com/) → project **`devops-portfolio-x-k3-y`**
2. Environment **`prod`**
3. Path / folder **`/cosign`**
4. Create/update secret:
   - **Name:** `cosign-public-key` (exact name under `/cosign`)
   - **Value:** cosign public PEM (`-----BEGIN PUBLIC KEY-----` …)

### 3b. Create machine identity

1. **Organization → Access Control → Identities → Create identity**
   - Name: e.g. `orbstack-platform-verify`
   - Org role: **Member**
2. Keep **Universal Auth** (default). Do **not** configure Kubernetes Auth for OrbStack.
3. **Create Client Secret** → copy **Client ID** and **Client Secret** (secret shown once).
4. **Project `devops-portfolio-x-k3-y` → Access Control → Machine Identities → Add identity**
   - Select `orbstack-platform-verify`
   - Role: can **read** secrets at `/cosign`

---

## 4. Put Universal Auth credentials on the cluster (not in git)

```bash
kubectl config use-context orbstack

kubectl create namespace platform-system --dry-run=client -o yaml | kubectl apply -f -

kubectl -n platform-system create secret generic universal-auth-credentials \
  --from-literal=clientId='PASTE_CLIENT_ID' \
  --from-literal=clientSecret='PASTE_CLIENT_SECRET' \
  --dry-run=client -o yaml | kubectl apply -f -
```

Never commit Client Secret to the repo.

---

## 5. Apply bootstrap root (platform once)

```bash
kubectl apply -f argocd/root-bootstrap.yaml
```

This creates `platform-root-bootstrap` → ApplicationSet `charts-bootstrap`, which
discovers `charts/bootstrap-layer/*/app.yaml` and installs (by sync wave):

| Wave | Apps |
|------|------|
| 0 | metrics-server, Kyverno, kube-prometheus-stack |
| 1 | Infisical secrets-operator |
| 2 | InfisicalSecret (git CR uses K8s auth placeholder), Teleport (manual) |
| 3 | Kyverno ClusterPolicies |
| 4 | Policy Reporter UI (+ Kyverno plugin) |

```bash
kubectl -n argocd get applicationset charts-bootstrap
kubectl -n argocd get applications -l platform.env=bootstrap
kubectl -n infisical-system get pods   # wait Ready
kubectl -n kyverno get pods
kubectl -n monitoring get pods
kubectl -n policy-reporter get pods
# UI: kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8082:8080
# then open http://127.0.0.1:8082
```

**Teleport** stays unsynced until configured (`autoSync: false`). Leave it.

---

## 6. Cosign Secret via Universal Auth (OrbStack overlay)

Git’s `InfisicalSecret` defaults to `kubernetesAuth` (for EKS). On OrbStack, apply
a **local** Universal Auth CR so the operator syncs the key:

```bash
kubectl apply -f - <<'EOF'
apiVersion: secrets.infisical.com/v1alpha1
kind: InfisicalSecret
metadata:
  name: cosign-public-key
  namespace: platform-system
spec:
  hostAPI: https://app.infisical.com/api
  authentication:
    universalAuth:
      credentialsRef:
        secretName: universal-auth-credentials
        secretNamespace: platform-system
      secretsScope:
        projectSlug: devops-portfolio-x-k3-y
        envSlug: prod
        secretsPath: /cosign
        recursive: false
  managedKubeSecretReferences:
    - secretName: cosign-public-key
      secretNamespace: platform-system
      creationPolicy: Owner
      template:
        includeAllSecrets: false
        data:
          # Infisical secret name under /cosign is cosign-public-key
          cosign.pub: '{{ (index . "cosign-public-key").Value }}'
EOF
```

If Argo’s `bootstrap-infisical-secrets` app reverts this to the git (kubernetesAuth)
manifest, pause that app while developing locally:

```bash
kubectl -n argocd patch application bootstrap-infisical-secrets --type merge \
  -p '{"spec":{"syncPolicy":null}}'
# re-apply the Universal Auth InfisicalSecret above
```

### Verify key sync

```bash
kubectl -n platform-system get infisicalsecret cosign-public-key
kubectl -n platform-system get secret cosign-public-key \
  -o jsonpath='{.data.cosign\.pub}' | base64 -d | head
```

### Fallback (no operator)

```bash
kubectl -n platform-system create secret generic cosign-public-key \
  --from-file=cosign.pub=./cosign.pub \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## 7. Apply workload root (pick one env)

Env = **which root file you apply** (not a cluster “mode”):

```bash
# Dev only (recommended for OrbStack)
kubectl apply -f argocd/root-dev.yaml

# Optional later:
# kubectl apply -f argocd/root-uat.yaml
# kubectl apply -f argocd/root-prod.yaml   # prod has autoSync: false — sync manually in Argo UI/CLI
```

`root-dev` → ApplicationSet `charts-dev` → only `charts/applications/*/apps/dev.yaml`
(e.g. `demo-app-dev` in namespace `demo-app-dev`).

```bash
kubectl -n argocd get applicationset charts-dev
kubectl -n argocd get applications -l platform.env=dev
kubectl -n demo-app-dev get deploy,svc
kubectl get clusterpolicy
```

Pinned image must be **multi-arch** (`v0.2.0+`). Older amd64-only digests fail on
Apple Silicon OrbStack with `no matching manifest for linux/arm64`.

### Verify Kyverno on `demo-app-dev`

Digest + cosign ClusterPolicies include `demo-app-dev`. After policies are Ready:

```bash
# Deny (expect admission webhook errors)
kubectl -n demo-app-dev run bad-tag --restart=Never \
  --image=ghcr.io/sauravrana646/portfolio-secure-cicd:v0.2.0
kubectl -n demo-app-dev run bad-sig --restart=Never \
  --image=ghcr.io/sauravrana646/portfolio-secure-cicd@sha256:0000000000000000000000000000000000000000000000000000000000000001

# Allow path — annotation proves verifyImages
kubectl -n demo-app-dev rollout restart deploy/demo-app-api
kubectl -n demo-app-dev get pod -l app=demo-app-api \
  -o jsonpath='{.items[0].metadata.annotations.kyverno\.io/verify-images}{"\n"}'
```

More detail: [`RUNBOOK.md`](RUNBOOK.md), [`policy/kyverno/README.md`](../policy/kyverno/README.md).

---

## 8. Access the stack

```bash
# App (service name is demo-app-api)
kubectl -n demo-app-dev port-forward svc/demo-app-api 8080:80
curl -s http://127.0.0.1:8080/healthz

# Grafana (password from helm-values/bootstrap-layer/kube-prometheus-stack — default changeme)
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# http://127.0.0.1:3000

# Prometheus
kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090

# Policy Reporter UI (Kyverno PolicyReports / ClusterPolicies)
kubectl -n policy-reporter port-forward svc/policy-reporter-ui 8082:8080
# http://127.0.0.1:8082
```

Argo UI (typical OrbStack / port-forward install):

```bash
kubectl -n argocd port-forward svc/argocd-server 8081:443
# https://127.0.0.1:8081
```

---

## 9. Tear down

```bash
# One env
kubectl -n argocd delete application platform-root-dev --ignore-not-found
kubectl -n argocd delete applicationset charts-dev --ignore-not-found

# Platform (optional — removes Kyverno, monitoring, …)
kubectl -n argocd delete application platform-root-bootstrap --ignore-not-found
kubectl -n argocd delete applicationset charts-bootstrap --ignore-not-found

# Local credentials / synced key
kubectl -n platform-system delete secret universal-auth-credentials cosign-public-key --ignore-not-found
kubectl -n platform-system delete infisicalsecret cosign-public-key --ignore-not-found
```

OrbStack cluster and Argo CD install stay unless you remove them in OrbStack.

---

## Quick reference

```bash
kubectl config use-context orbstack
git pull origin main

# Infisical Universal Auth credentials (once)
kubectl -n platform-system create secret generic universal-auth-credentials \
  --from-literal=clientId='…' --from-literal=clientSecret='…'

kubectl apply -f argocd/root-bootstrap.yaml
# apply Universal Auth InfisicalSecret (section 6)
kubectl apply -f argocd/root-dev.yaml
```

| Root | Purpose |
|------|---------|
| `argocd/root-bootstrap.yaml` | Platform charts |
| `argocd/root-dev.yaml` | Dev workloads only |
| `argocd/root-uat.yaml` | UAT workloads only |
| `argocd/root-prod.yaml` | Prod workloads only (manual sync) |

More on ApplicationSets: [`argocd/README.md`](../argocd/README.md).  
EKS / Kubernetes Auth (not OrbStack): [Infisical Kubernetes Auth](https://infisical.com/docs/documentation/platform/identities/kubernetes-auth).
