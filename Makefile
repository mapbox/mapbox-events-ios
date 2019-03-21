OUTPUT_PATH = build
PROJ_PATH = $(IOS_OUTPUT_PATH)/mbgl.xcodeproj

.PHONY: name-header
name-header:
	./scripts/package.sh -h

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

.PHONE: preflight-checks
preflight-checks: pod-lint
