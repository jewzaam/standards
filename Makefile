PYTHON := python

.PHONY: all check install-dev markdown-lint links reachability test help

all: check  ## Run all checks (default)

check: markdown-lint links reachability test  ## Run all validation

install-dev:  ## Install development dependencies
	$(PYTHON) -m pip install --quiet 'pymarkdownlnt>=0.9.36'

markdown-lint: install-dev  ## Lint markdown files
	@echo "Linting markdown files..."
	$(PYTHON) -m pymarkdown --disable-rules MD013,MD024,MD031,MD036 scan .

links:  ## Validate local markdown links and anchors
	@echo "Validating local links..."
	$(PYTHON) scripts/check-links.py

reachability:  ## Verify all files are reachable from README.md and CLAUDE.md
	@echo "Checking document reachability..."
	$(PYTHON) scripts/reachability.py --check

test:  ## Run fabcheck fixture tests
	@bash tests/fabcheck/run-tests.sh

help:  ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := all
