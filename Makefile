.PHONY: help up down test helm-lint helm-template tf-validate cluster-deploy cluster-down cluster-status plan apply verify-image compose-config

IMAGE_FILE ?= deploy/environments/dev/images.yaml
INFISICAL_PROJECT_SLUG ?= devops-portfolio-x-k3-y
INFISICAL_ENV_SLUG ?= prod
INFISICAL_SECRET_PATH ?= /cosign

help:
	@echo "up down compose-config verify-image helm-lint helm-template cluster-deploy cluster-down cluster-status tf-validate plan apply"

up:
	docker compose up -d

down:
	docker compose down -v

compose-config:
	docker compose config -q

# Fetch cosign-public-key from Infisical (OIDC/CLI login) and verify the pinned digest.
# Requires: cosign, and either INFISICAL_* env from `infisical export` or a logged-in Infisical CLI.
verify-image:
	@set -euo pipefail; \
	REPO=$$(awk '/repository:/ {print $$2; exit}' $(IMAGE_FILE)); \
	DIGEST=$$(awk '/digest:/ {print $$2; exit}' $(IMAGE_FILE)); \
	IMAGE_REF="$${REPO}@$${DIGEST}"; \
	echo "Verifying $${IMAGE_REF}"; \
	if [ -z "$${cosign_public_key:-}" ] && [ -z "$${COSIGN_PUBLIC_KEY:-}" ]; then \
	  if command -v infisical >/dev/null 2>&1; then \
	    eval "$$(infisical export --env=$(INFISICAL_ENV_SLUG) --path=$(INFISICAL_SECRET_PATH) --projectId=$(INFISICAL_PROJECT_SLUG) --format=dotenv 2>/dev/null | sed 's/^/export /' || true)"; \
	  fi; \
	fi; \
	KEY="$${cosign_public_key:-$${COSIGN_PUBLIC_KEY:-}}"; \
	if [ -z "$$KEY" ]; then \
	  echo "cosign-public-key not set. Run with Infisical CLI/OIDC or export cosign_public_key / COSIGN_PUBLIC_KEY."; \
	  exit 1; \
	fi; \
	tmp=$$(mktemp); \
	printf '%s\n' "$$KEY" > "$$tmp"; \
	cosign verify --key "$$tmp" "$$IMAGE_REF"; \
	cosign verify-attestation --key "$$tmp" --type spdx "$$IMAGE_REF" >/dev/null; \
	rm -f "$$tmp"; \
	echo "Signature + SPDX attestation OK"

helm-lint:
	helm lint charts/demo-app

helm-template:
	helm template demo charts/demo-app \
		-f charts/demo-app/values.yaml \
		-f deploy/environments/dev/images.yaml \
		-f deploy/environments/dev/values.yaml >/dev/null
	helm template demo charts/demo-app \
		-f charts/demo-app/values.yaml \
		-f charts/demo-app/values-staging.yaml \
		-f deploy/environments/uat/images.yaml \
		-f deploy/environments/uat/values.yaml >/dev/null
	helm template demo charts/demo-app \
		-f charts/demo-app/values.yaml \
		-f charts/demo-app/values-prod.yaml \
		-f deploy/environments/prod/images.yaml \
		-f deploy/environments/prod/values.yaml >/dev/null

tf-validate:
	cd infra/terraform && terraform init -backend=false && terraform validate

plan:
	cd infra/terraform && terraform init -backend=false && terraform plan -var='deploy_target=local'

apply:
	@echo "Refusing apply. Pass explicit approval and run terraform apply manually in a sandbox."

# Uses current kubectl context (OrbStack, kind, k3d, etc.).
cluster-deploy:
	@echo "Using kubectl context: $$(kubectl config current-context)"
	kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install demo charts/demo-app \
		--namespace demo \
		-f charts/demo-app/values.yaml \
		-f charts/demo-app/values-staging.yaml \
		-f deploy/environments/dev/images.yaml \
		-f deploy/environments/dev/values.yaml \
		--wait --timeout 180s
	@echo "Port-forward: kubectl -n demo port-forward svc/demo-api 8080:80"

cluster-status:
	kubectl config current-context
	kubectl -n demo get deploy,svc,pdb,networkpolicy,sa 2>/dev/null || true

cluster-down:
	helm uninstall demo --namespace demo || true
	kubectl delete namespace demo --ignore-not-found

test:
	@echo "No in-repo app unit tests; workload is upstream portfolio-secure-cicd."
	@echo "Running platform checks: compose-config helm-lint helm-template"
	$(MAKE) compose-config helm-lint helm-template
