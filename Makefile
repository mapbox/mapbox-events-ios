
BUILD_DIR = build
BUILD_PROJECT ?= MapboxMobileEvents.xcodeproj
BUILD_SCHEME ?= MapboxMobileEvents
TEST_SCHEME ?= MMETestHost
TEST_DESTINATION ?= 'platform=iOS Simulator,name=iPhone 11,OS=latest'
TEST_FLAGS ?= GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=YES GCC_GENERATE_TEST_COVERAGE_FILES=YES
XCODEBUILD ?= xcodebuild
DESTINATION ?= name=Generic iOS Device

# Build Driver Targets

.PHONY: prep
prep:
	@echo "TODO prep Project"

.PHONY: build
build:
	$(XCODEBUILD) -scheme "$(BUILD_SCHEME)" build

.PHONY: test
test:
	$(XCODEBUILD) -project "$(BUILD_PROJECT)" -scheme "$(TEST_SCHEME)" build test -destination $(TEST_DESTINATION) $(TEST_FLAGS)

.PHONY: docs
docs:
	@echo "TODO docs Project"

.PHONY: pack
pack:
	@echo "TODO pack Project"

.PHONY: farm
farm:
	@echo "TODO farm Project"

.PHONY: stage
stage:
	@echo "TODO stage Project"

.PHONY: clean
clean:
	@[ -d $(BUILD_DIR) ] && rm -fr $(BUILD_DIR) || true

.PHONY: lint
lint:

# local and ci build Targets

.DEFAULT: build
run: prep build test docs pack

.PHONY: ci-build
ci-run: tools build
