include build.vars

#VANILLA_REPO := aksw/fuseki-vanilla
#IMAGE_REPO := aksw/fuseki-plus
SYNC_FILES := README.md example/docker-compose.yaml tests/docker-compose.yaml tests/run-tests.sh

.DEFAULT_GOAL := help
.PHONY: sync-version build push

.ONESHELL:
help: ## Show these help instructions
	@sed -rn 's/^([^: ]*)[^:]*:[^#]*## (.*)$$/"\1" "\2"/p' $(MAKEFILE_LIST) | xargs printf "make %-15s # %s\n"

sync-version: ## Sync versions in README.md, example/docker-compose.yaml, and tests with build.vars
	@sed -i.bak "s|^FROM $(VANILLA_REPO):.*|FROM $(VANILLA_REPO):$(VANILLA_VERSION)|" Dockerfile && rm -f Dockerfile.bak
	@for f in $(SYNC_FILES); do \
	  sed -i.bak \
	    -e "s|$(VANILLA_REPO):[0-9][0-9.-]*|$(VANILLA_REPO):$(VANILLA_VERSION)|g" \
	    -e "s|$(IMAGE_REPO):[0-9][0-9.-]*|$(IMAGE_REPO):$(IMAGE_TAG)|g" \
	    -e "s|^Current \(image \)\?version: .*|Current image version: **$(IMAGE_TAG)** (vanilla $(VANILLA_VERSION))|" \
	    "$$f" && rm -f "$$f.bak"; \
	done
	@echo "synced: Dockerfile <- VANILLA_VERSION=$(VANILLA_VERSION), docs <- IMAGE_TAG=$(IMAGE_TAG)" >&2

build: ## Build the docker image with versions derived from build.vars
	@IMAGE="$(IMAGE_REPO):$(IMAGE_TAG)"
	docker build --no-cache -t "$$IMAGE" .
	@echo "Built: $$IMAGE" >&2

push: ## Push a previously built image
	@IMAGE="$(IMAGE_REPO):$(IMAGE_TAG)"
	@echo "Pushing in 5 seconds: $$IMAGE"
	@sleep 5 # Change to abort if goal was invoked in mistake
	docker push "$$IMAGE"
	@echo "Pushed: $$IMAGE" >&2
