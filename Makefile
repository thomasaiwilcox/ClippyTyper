.DEFAULT_GOAL := help
.PHONY: build test lint format open clean help

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
