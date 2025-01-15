.PHONY: build build-no-cache build-multiarch cleanup run test test-ci-setup test-ci autoupdate-drawio-desktop

# amd64 by default, arm64 for arm machine like macbook m1
ifneq ($(filter arm%,$(shell uname -p)),)
ARCHFLAG := "arm64"
else
ARCHFLAG := "amd64"
endif

# attempt to build with docker or podman
ifeq ($(shell command -v podman 2> /dev/null),)
	CMD=docker
else
	CMD=podman
endif

DOCKER_IMAGE?=sob/drawio-desktop-headless:local
build:
	$(CMD) build --build-arg="TARGETARCH=$(ARCHFLAG)" \
		--build-arg="BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')" \
		--build-arg="VCS_REF=$(shell git rev-parse --short HEAD)" \
		-f Dockerfile \
		-t ${DOCKER_IMAGE} .
	$(CMD) image prune -f

build-no-cache:
	$(CMD) build --build-arg="TARGETARCH=$(ARCHFLAG)" \
		--build-arg="BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')" \
		--build-arg="VCS_REF=$(shell git rev-parse --short HEAD)" \
		--no-cache \
		--progress plain \
		-f Dockerfile \
		-t ${DOCKER_IMAGE} .

build-multiarch:
	@docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--build-arg="BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')" \
		--build-arg="VCS_REF=$(shell git rev-parse --short HEAD)" \
		-f Dockerfile \
		-t ${DOCKER_IMAGE} .

cleanup:
	@rm -rf tests/output
	@rm -rf tests/data/home
	@find tests/data \( -name "*.pdf" -o -name "*.svg" -o -name "*.png" \) -delete

RUN_ARGS?=
DOCKER_OPTIONS?=
run:
	$(CMD) run -t $(DOCKER_OPTIONS) -w /data -v $(PWD):/data ${DOCKER_IMAGE} ${RUN_ARGS}

test: cleanup build test-ci

test-ci-setup:
	@npm install bats
	@sudo apt-get install -y libxml2-utils

test-ci:
	@mkdir -p tests/output
	@DOCKER_IMAGE=$(DOCKER_IMAGE) npx bats --verbose-run -r tests

autoupdate-drawio-desktop:
	@$(eval DRAWIO_DESKTOP_RELEASE := $(shell gh release list --repo jgraph/drawio-desktop | grep "Latest" | cut -f1))
	@sed -i 's/DRAWIO_VERSION=.*/DRAWIO_VERSION="$(DRAWIO_DESKTOP_RELEASE)"/' Dockerfile
	@sed -i 's/Draw\.io Desktop v.*/Draw.io Desktop v$(DRAWIO_DESKTOP_RELEASE)\]/' README.adoc
	@test -z "${GITHUB_OUTPUT}" || echo "release_version=$(DRAWIO_DESKTOP_RELEASE)" >> "${GITHUB_OUTPUT}"
