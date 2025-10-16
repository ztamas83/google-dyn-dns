.PHONY: build-ts deploy-ts

build:
	@echo "Building dns-updater-ts..."
	@cd dns-updater-ts && npm install && npm run build
	@echo "Build complete."

deploy: build
	@echo "Deploying dns-updater-ts..."
	@cd infrastructure && terraform apply -auto-approve -backend-config=dyndns.backend
	@echo "Deployment complete."
