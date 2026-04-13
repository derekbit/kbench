MACHINE := longhorn

.PHONY: build validate ci package clean

buildx-machine:
	@docker buildx create --name=$(MACHINE) 2>/dev/null || true

build: buildx-machine
	docker buildx build --builder=$(MACHINE) --target build-artifacts --output type=local,dest=. -f Dockerfile .

validate:
	docker buildx build --target validate -f Dockerfile .

ci: buildx-machine
	docker buildx build --builder=$(MACHINE) --target ci-artifacts --output type=local,dest=. -f Dockerfile .

package: build
	./scripts/package

clean:
	rm -rf bin dist

.DEFAULT_GOAL := ci

