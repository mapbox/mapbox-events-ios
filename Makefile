OUTPUT_PATH = build

.PHONY: get-current-version
get-current-version:
	./scripts/package.sh -v

.PHONY: tag-version
tag-version:
	./scripts/package.sh -t $(VERSION)

.PHONY: create-static
create-static:
	./scripts/package.sh -s

.PHONY: pod-lint
pod-lint:
	pod lib lint

DOCS_DIR := docs
DOCS_INDEX = $(DOCS_DIR)/index.html
DOCS_README = readme.md
DOCS_LICENSE = LICENSE.md
LOWDOWN_PATH = $(shell which lowdown)
MARKDOWN_PATH = $(shell which multimarkdown)

DEBUG_SCHEME ?= MapboxMobileEvents
RELEASE_SCHEME ?= MapboxMobileEvents (Release)
DEPRECATION_SCHEME ?= MapboxMobileEvents (Deprecation)
BUILD_SCHEME ?= $(RELEASE_SCHEME)

XCODEBUILD ?= xcodebuild
DESTINATION ?= name=Generic iOS Device

ifneq ($(LOWDOWN_PATH),)
	MARKDOWN_TOOL = $(LOWDOWN_PATH)
	MARKDOWN_ARGS = "-so"
else ifneq ($(MARKDOWN_PATH),)
	MARKDOWN_TOOL = $(MARKDOWN_PATH)
	MARKDOWN_ARGS = "-s"
endif

.PHONY: headerdoc
headerdoc:
	find MapboxMobileEvents -type f -name '*.h' | xargs headerdoc2html -o $(DOCS_DIR)
	gatherheaderdoc $(DOCS_DIR)

.PHONY: docindex
docindex:
	echo "<html><head><title>MapboxMobileEvents</title><meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"><body>" > $(DOCS_INDEX)
	$(MARKDOWN_TOOL) $(MARKDOWN_ARGS) $(DOCS_README) >> $(DOCS_INDEX)
	echo "<h2>License</h2><tt>" >> $(DOCS_INDEX)
	$(MARKDOWN_TOOL) $(MARKDOWN_ARGS) $(DOCS_LICENSE) >> $(DOCS_INDEX)
	echo "</tt></body></html>" >> $(DOCS_INDEX)

.PHONY: docs
docs: $(DOCS_DIR) headerdoc docindex
	open $(DOCS_INDEX)

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

# driver targets
.PHONY: pod-lint
prep: pod-lint

.PHONY: build
build:
	$(XCODEBUILD) -scheme "$(BUILD_SCHEME)" build
	
.PHONY: test
test:
	$(XCODEBUILD) -scheme "$(BUILD_SCHEME)" test

.PHONY: docs
docs:

.PHONY: pack
pack:

.PHONY: clean
clean:
	rm -fr $(OUTPUT_PATH)
