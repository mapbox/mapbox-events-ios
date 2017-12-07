OUTPUT_PATH = build
PROJ_PATH = $(IOS_OUTPUT_PATH)/mbgl.xcodeproj

.PHONY: name-header
name-header:
	./scripts/package.sh
