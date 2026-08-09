.PHONY: help up down test helm-lint helm-template helm-deps tf-validate cluster-deploy cluster-down cluster-status plan apply verify-image compose-config

COMPOSE_FILE ?= local/docker-compose.yml
IMAGE_FILE ?= helm-values/applications/demo-app/environments/dev/images.yaml
CHART_APP ?= charts/applications/demo-app
INFISICAL_PROJECT_SLUG ?= devops-portfolio-x-k3-y
INFISICAL_ENV_SLUG ?= prod
INFISICAL_SECRET_PATH ?= /cosign

help:
	@echo "up down compose-config verify-image helm-deps helm-lint helm-template cluster-deploy cluster-down cluster-status tf-validate plan apply"

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down -v

compose-config:
	docker compose -f $(COMPOSE_FILE) config -q

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

helm-deps:
	@set -euo pipefail; \
	for d in kyverno kube-prometheus-stack metrics-server infisical-operator teleport-kube-agent; do \
	  echo "==> helm dependency update charts/bootstrap-layer/$$d"; \
	  helm dependency update "charts/bootstrap-layer/$$d"; \
	done

helm-lint:
	helm lint $(CHART_APP)

helm-template:
	helm template demo $(CHART_APP) \
		-f helm-values/applications/demo-app/values.yaml \
		-f helm-values/applications/demo-app/environments/dev/values.yaml \
		-f helm-values/applications/demo-app/environments/dev/images.yaml >/dev/null
	helm template demo $(CHART_APP) \
		-f helm-values/applications/demo-app/values.yaml \
		-f helm-values/applications/demo-app/environments/uat/values.yaml \
		-f helm-values/applications/demo-app/environments/uat/images.yaml >/dev/null
	helm template demo $(CHART_APP) \
		-f helm-values/applications/demo-app/values.yaml \
		-f helm-values/applications/demo-app/environments/prod/values.yaml \
		-f helm-values/applications/demo-app/environments/prod/images.yaml >/dev/null

tf-validate:
	cd infra/terraform && terraform init -backend=false && terraform validate

plan:
	cd infra/terraform && terraform init -backend=false && terraform plan -var='deploy_target=local'

apply:
	@echo "Refusing apply. Pass explicit approval and run terraform apply manually in a sandbox."

cluster-deploy:
	@echo "Using kubectl context: $$(kubectl config current-context)"
	kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install demo $(CHART_APP) \
		--namespace demo \
		-f helm-values/applications/demo-app/values.yaml \
		-f helm-values/applications/demo-app/environments/dev/values.yaml \
		-f helm-values/applications/demo-app/environments/dev/images.yaml \
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
