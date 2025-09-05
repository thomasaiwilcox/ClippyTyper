.DEFAULT_GOAL := help
.PHONY: build test lint format open clean help xcode xcode-build xcode-test

# Defaults (override via: make SCHEME=YourScheme)
SCHEME ?= ClippyTyper
CONFIGURATION ?= Debug
DESTINATION ?= platform=macOS

PROJECT := $(shell ls -1 *.xcodeproj 2>/dev/null | head -n1)
WORKSPACE := $(shell ls -1 *.xcworkspace 2>/dev/null | head -n1)

ifeq ($(strip $(WORKSPACE)),)
XCODE_TARGET = -project "$(PROJECT)"
else
XCODE_TARGET = -workspace "$(WORKSPACE)"
endif

build:
	@if [ -f Package.swift ]; then \
		echo "[swiftpm] swift build"; \
		swift build; \
	elif [ -n "$(PROJECT)$(WORKSPACE)" ]; then \
		echo "[xcodebuild] build $(SCHEME)"; \
		xcodebuild $(XCODE_TARGET) -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination '$(DESTINATION)' build; \
	else \
		echo "No Package.swift or Xcode project/workspace found."; \
		exit 1; \
	fi

test:
	@if [ -f Package.swift ]; then \
		echo "[swiftpm] swift test"; \
		swift test; \
	elif [ -n "$(PROJECT)$(WORKSPACE)" ]; then \
		echo "[xcodebuild] test $(SCHEME)"; \
		xcodebuild $(XCODE_TARGET) -scheme "$(SCHEME)" -destination '$(DESTINATION)' test; \
	else \
		echo "No Package.swift or Xcode project/workspace found."; \
		exit 1; \
	fi

lint:
	@./Scripts/lint.sh

format:
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat .; \
	else \
		echo "swiftformat not installed"; \
	fi

open:
	@if [ -n "$(WORKSPACE)" ]; then \
		open "$(WORKSPACE)"; \
	elif [ -n "$(PROJECT)" ]; then \
		open "$(PROJECT)"; \
	else \
		echo "No Xcode workspace/project found."; \
	fi

clean:
	@if [ -f Package.swift ]; then swift package clean; fi
	@if [ -n "$(PROJECT)$(WORKSPACE)" ]; then \
		xcodebuild $(XCODE_TARGET) -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" clean; \
	fi

help:
	@echo "Usage: make [TARGET] [SCHEME=…] [CONFIGURATION=…] [DESTINATION=…]"
	@echo "Defaults: SCHEME=$(SCHEME), CONFIGURATION=$(CONFIGURATION), DESTINATION=$(DESTINATION)"
	@echo
	@echo "Targets:"
	@printf "  %-12s %s\n" build   "Build the app (SwiftPM or Xcode)"
	@printf "  %-12s %s\n" test    "Run tests"
	@printf "  %-12s %s\n" lint    "Run linters (swiftformat/swiftlint)"
	@printf "  %-12s %s\n" format  "Format with swiftformat"
	@printf "  %-12s %s\n" open    "Open project/workspace in Xcode"
	@printf "  %-12s %s\n" clean   "Clean build artifacts"
	@printf "  %-12s %s\n" xcode   "Generate Xcode project via XcodeGen and open it"
	@printf "  %-12s %s\n" xcode-build "Build generated Xcode project (ClippyTyper scheme)"
	@printf "  %-12s %s\n" xcode-test "Test generated Xcode project (scheme's test action)"

xcode:
	@if [ ! -f xcode/project.yml ]; then \
		echo "xcode/project.yml not found"; \
		exit 1; \
	fi
	@if ! command -v xcodegen >/dev/null 2>&1; then \
		echo "XcodeGen not installed. Install via 'brew install xcodegen'"; \
		exit 1; \
	fi
	@echo "[xcodegen] Generating Xcode project…"
	@cd xcode && xcodegen generate
	@open xcode/ClippyTyper.xcodeproj

XCODE_SCHEME ?= ClippyTyper
xcode-build:
	@if [ ! -f xcode/project.yml ]; then \
		echo "xcode/project.yml not found"; \
		exit 1; \
	fi
	@if [ ! -d xcode/ClippyTyper.xcodeproj ]; then \
		if ! command -v xcodegen >/dev/null 2>&1; then \
			echo "Xcode project missing and XcodeGen not installed. Install via 'brew install xcodegen'"; \
			exit 1; \
		fi; \
		echo "[xcodegen] Generating Xcode project…"; \
		cd xcode && xcodegen generate; \
	fi
	@echo "[xcodebuild] Building scheme $(XCODE_SCHEME) (CONFIGURATION=$(CONFIGURATION))"
	xcodebuild -project xcode/ClippyTyper.xcodeproj -scheme "$(XCODE_SCHEME)" -configuration "$(CONFIGURATION)" -destination 'platform=macOS' build

xcode-test:
	@if [ ! -f xcode/project.yml ]; then \
		echo "xcode/project.yml not found"; \
		exit 1; \
	fi
	@if [ ! -d xcode/ClippyTyper.xcodeproj ]; then \
		if ! command -v xcodegen >/dev/null 2>&1; then \
			echo "Xcode project missing and XcodeGen not installed. Install via 'brew install xcodegen'"; \
			exit 1; \
		fi; \
		echo "[xcodegen] Generating Xcode project…"; \
		cd xcode && xcodegen generate; \
	fi
	@echo "[xcodebuild] Testing scheme $(XCODE_SCHEME)"
	xcodebuild -project xcode/ClippyTyper.xcodeproj -scheme "$(XCODE_SCHEME)" -destination 'platform=macOS' test
