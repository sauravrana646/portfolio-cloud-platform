.PHONY: help up down test plan apply helm-lint tf-validate kind-load
help:
	@echo "up down test helm-lint tf-validate plan apply"

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

kind-load:
	docker build -t portfolio-cloud-platform-api:local app/api
	kind load docker-image portfolio-cloud-platform-api:local || true
	helm upgrade --install demo charts/demo-app --set image.repository=portfolio-cloud-platform-api --set image.tag=local
