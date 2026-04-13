PROJECT := kbench
MACHINE := longhorn
DEFAULT_PLATFORMS := linux/amd64,linux/arm64

.PHONY: build validate ci package clean

buildx-machine:
	@docker buildx create --name=$(MACHINE) --platform=$(DEFAULT_PLATFORMS) 2>/dev/null || true
	docker buildx inspect $(MACHINE)

build: buildx-machine
	docker buildx build --builder=$(MACHINE) --target build-artifacts --output type=local,dest=. -f Dockerfile .

validate:
	docker buildx build --target validate -f Dockerfile .

ci: buildx-machine
	docker buildx build --builder=$(MACHINE) --target ci-artifacts --output type=local,dest=. -f Dockerfile .

package:
	bash scripts/package

.PHONY: workflow-image-build-push workflow-image-build-push-secure
workflow-image-build-push: buildx-machine
	MACHINE=$(MACHINE) PUSH='true' IMAGE_NAME=$(PROJECT) bash scripts/package
workflow-image-build-push-secure: buildx-machine
	MACHINE=$(MACHINE) PUSH='true' IMAGE_NAME=$(PROJECT) IS_SECURE=true bash scripts/package

clean:
	rm -rf bin dist

.DEFAULT_GOAL := ci

