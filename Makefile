.PHONY: test lint install clean help

SHELL := /bin/bash
PREFIX ?= $(HOME)/.local

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

test: ## Run all tests
	@bash tests/run-all.sh

lint: ## Run shellcheck on all shell scripts
	@echo "Running shellcheck..."
	@find bin lib commands tests -name '*.sh' -o -name 'sentinels-toolkit' | \
		xargs shellcheck --severity=error && \
		echo "✓ shellcheck passed" || \
		echo "✗ shellcheck found issues"

install: ## Install sentinels-toolkit to PREFIX/bin (default: ~/.local/bin)
	@mkdir -p $(PREFIX)/bin
	@cp bin/sentinels-toolkit $(PREFIX)/bin/sentinels-toolkit
	@chmod +x $(PREFIX)/bin/sentinels-toolkit
	@echo "Installed to $(PREFIX)/bin/sentinels-toolkit"
	@echo "Make sure $(PREFIX)/bin is in your PATH"

clean: ## Remove generated files
	@rm -f tests/.test-results tests/.test-failed
	@echo "Cleaned."
