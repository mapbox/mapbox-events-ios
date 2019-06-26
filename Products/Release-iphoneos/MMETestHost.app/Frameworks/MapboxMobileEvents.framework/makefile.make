DEVICE_ID := $(strip $(shell system_profiler SPUSBDataType | sed -n -E -e "/(iPhone|iPad)/,/Serial/s/ *Serial Number: *(.+)/\1/p" ))

#
# Prerequisites
#

ifeq ($(DEVICE_ID),)
$(info No device detected by USB)
endif

#
# Variables
#

# Common variables
DATE := $(shell date +"%Y-%m-%d_%H%M%S")
CURRENT_DIR := $(shell pwd)
SCRIPTS_DIR := $(CURRENT_DIR)/Scripts
BUILD_DIR := $(CURRENT_DIR)/Products
TRACES_DIR := $(CURRENT_DIR)/Traces
BENCHMARKS_DIR := $(CURRENT_DIR)/Benchmarks

# trace-parser
# Instruments doesn't currently run on AWS Device Farm
DEFAULT_TRACE_LOG := $(TRACES_DIR)/trace-$(DATE).trace
TRACE_LOG ?= $(DEFAULT_TRACE_LOG)
TRACE_JSON := $(TRACE_LOG:.trace=.json)

TRACE_PARSER_XPROJ := $(CURRENT_DIR)/vendor/trace-parser/trace-parser.xcodeproj
TRACE_PARSER_DIR := $(BUILD_DIR)/Release
TRACE_PARSER_APP := trace-parser
TRACE_PARSER := $(TRACE_PARSER_DIR)/$(TRACE_PARSER_APP)

# Mobile Metrics project
MMETestHost_XPROJ := $(CURRENT_DIR)/MapboxMobileEvents.xcodeproj
MMETestHost_APP := $(BUILD_DIR)/MMETestHost.app
MMETestHost_UI_TEST_RUNNER_APP := $(BUILD_DIR)/MMETestHostUITests.app

.PHONY: install-metrics-app
install-metrics-app:
ifeq ($(DEVICE_ID),)
	@echo "No device - skipping installation"
else
	xcodebuild -project $(MMETestHost_XPROJ) -scheme MMETestHost-leaks -sdk iphoneos -configuration Release test -only-testing:MMETestHostUITests 'platform=ios,id=$(DEVICE_ID)' BUILD_DIR=$(BUILD_DIR)
endif

# Profiling

$(TRACE_LOG): $(TRACES_DIR) install-metrics-app
ifeq ($(DEVICE_ID),)
	@echo "No device - skipping instruments"
else	
# ifeq ($(TEST_PARAMETERS),)
# 	@echo "No TEST_PARAMETERS specified - skipping instruments"
# else
	# Instruments adds new runs, so delete in case the file already exists
	-rm $(TRACE_LOG)
	instruments -w $(DEVICE_ID) -t Instruments/LeakTemplate.tracetemplate -D $(TRACE_LOG)
endif	


# If you want to profile a specific test: 
# > make profile TEST_PARAMETERS="-test animateFlyToLarge"
.PHONY: profile
profile: $(TRACE_LOG)


