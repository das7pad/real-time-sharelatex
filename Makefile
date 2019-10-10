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
	rm -f app.map
	rm -rf app/js
	rm -rf test/acceptance/js
	rm -rf test/load/js
	rm -rf test/smoke/js
	rm -rf test/unit/js

test: test_unit test_acceptance

test_unit:
	$(DOCKER_COMPOSE) run --rm test_unit

test_acceptance: test_clean test_acceptance_pre_run test_acceptance_run

test_acceptance_run:
	$(DOCKER_COMPOSE) run --rm test_acceptance

clean_test_acceptance:

test_clean:
	$(DOCKER_COMPOSE) down -v -t 0

test_acceptance_pre_run:

COFFEE := npx coffee --map

build_app: compile_full

compile_full: compile_app
compile_full: compile_tests

COFFEE_DIRS_TESTS := $(wildcard test/*/coffee)
COMPILE_TESTS := $(addprefix compile/,$(COFFEE_DIRS_TESTS))
compile_app: app.js compile/app/coffee
compile_tests: $(COMPILE_TESTS)

compile/app/coffee $(COMPILE_TESTS): compile/%coffee:
	$(COFFEE) --output $*js --compile $*coffee

COFFEE_FILES := $(shell find app/coffee $(COFFEE_DIRS_TESTS) -name '*.coffee')
JS_FILES := app.js $(subst /coffee,/js,$(subst .coffee,.js,$(COFFEE_FILES)))
compile: $(JS_FILES)

app.js: app.coffee
	$(COFFEE) --compile $<

app/js/%.js: app/coffee/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) --compile -o $(@D) $<

test/acceptance/js/%.js: test/acceptance/coffee/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) --compile -o $(@D) $<

test/load/js/%.js: test/load/coffee/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) --compile -o $(@D) $<

test/smoke/js/%.js: test/smoke/coffee/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) --compile -o $(@D) $<

test/unit/js/%.js: test/unit/coffee/%.coffee
	@mkdir -p $(@D)
	$(COFFEE) --compile -o $(@D) $<

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
