.PHONY: help up down test plan apply helm-lint tf-validate cluster-deploy cluster-down cluster-status
help:
	@echo "up down test helm-lint tf-validate cluster-deploy cluster-down cluster-status plan apply"

up:
	docker compose up --build -d

down:
	docker compose down -v

test:
	cd app/api && pip install -q -r requirements-dev.txt && pytest -q

helm-lint:
	helm lint charts/demo-app

tf-validate:
	cd infra/terraform && terraform init -backend=false && terraform validate

plan:
	cd infra/terraform && terraform init -backend=false && terraform plan -var='deploy_target=local'

apply:
	@echo "Refusing apply. Pass explicit approval and run terraform apply manually in a sandbox."

# Uses current kubectl context (OrbStack, k3d, etc.) — does not create a kind cluster.
# OrbStack shares the local Docker image store, so a local tag is enough.
cluster-deploy:
	@echo "Using kubectl context: $$(kubectl config current-context)"
	docker build -t portfolio-cloud-platform-api:local app/api
	kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install demo charts/demo-app \
		--namespace demo \
		-f charts/demo-app/values.yaml \
		-f charts/demo-app/values-staging.yaml \
		--set image.repository=portfolio-cloud-platform-api \
		--set image.tag=local \
		--set image.pullPolicy=IfNotPresent \
		--wait --timeout 120s
	@echo "Port-forward: kubectl -n demo port-forward svc/demo-api 8080:80"

cluster-status:
	kubectl config current-context
	kubectl -n demo get deploy,svc,pdb,networkpolicy 2>/dev/null || true

cluster-down:
	helm uninstall demo --namespace demo || true
	kubectl delete namespace demo --ignore-not-found
