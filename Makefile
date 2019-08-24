# This file was auto-generated, do not edit it directly.
# Instead run bin/update_build_scripts from
# https://github.com/das7pad/sharelatex-dev-env

BUILD_NUMBER ?= local
BRANCH_NAME ?= $(shell git rev-parse --abbrev-ref HEAD)
COMMIT ?= $(shell git rev-parse HEAD)
RELEASE ?= $(shell git describe --tags | sed 's/-g/+/;s/^v//')
PROJECT_NAME = real-time
DOCKER_COMPOSE_FLAGS ?= -f docker-compose.yml
DOCKER_COMPOSE := BUILD_NUMBER=$(BUILD_NUMBER) \
	BRANCH_NAME=$(BRANCH_NAME) \
	PROJECT_NAME=$(PROJECT_NAME) \
	MOCHA_GREP=${MOCHA_GREP} \
	docker-compose ${DOCKER_COMPOSE_FLAGS}

clean_ci: clean
clean_ci: clean_build
clean_ci: test_clean

clean_build:
	docker rmi \
		ci/$(PROJECT_NAME):$(BRANCH_NAME)-$(BUILD_NUMBER) \
		ci/$(PROJECT_NAME):$(BRANCH_NAME)-$(BUILD_NUMBER)-cache \
		--force

clean:

	rm -f app.js
	rm -rf app/js
	rm -rf test/unit/js
	rm -rf test/acceptance/js

test: test_unit test_acceptance

test_unit:
	@[ ! -d test/unit ] && echo "real-time has no unit tests" || $(DOCKER_COMPOSE) run --rm test_unit

test_acceptance: test_clean test_acceptance_pre_run test_acceptance_run

test_acceptance_run:
	@[ ! -d test/acceptance ] && echo "real-time has no acceptance tests" || $(DOCKER_COMPOSE) run --rm test_acceptance

clean_test_acceptance:

test_clean:
	$(DOCKER_COMPOSE) down -v -t 0

test_acceptance_pre_run:
	@[ ! -f test/acceptance/scripts/pre-run ] && echo "real-time has no pre acceptance tests task" || $(DOCKER_COMPOSE) run --rm test_acceptance test/acceptance/scripts/pre-run

build_app:
	npm run compile:all

build:
	docker build --tag ci/$(PROJECT_NAME):$(BRANCH_NAME)-$(BUILD_NUMBER) \
		--cache-from ci/$(PROJECT_NAME):$(BRANCH_NAME)-$(BUILD_NUMBER)-cache \
		--build-arg RELEASE=$(RELEASE) \
		--build-arg COMMIT=$(COMMIT) \
		.

tar:
	$(DOCKER_COMPOSE) up tar

publish:

	docker push $(DOCKER_REPO)/$(PROJECT_NAME):$(BRANCH_NAME)-$(BUILD_NUMBER)

.PHONY: clean test test_unit test_acceptance test_clean build publish
