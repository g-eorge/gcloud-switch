.PHONY: test lint check install help

help:
	@echo "gcloud-switch Makefile"
	@echo "====================="
	@echo ""
	@echo "Available targets:"
	@echo "  test    - Run test suite"
	@echo "  lint    - Run ShellCheck linting"
	@echo "  check   - Run lint and test"
	@echo "  install - Install wrapper script"
	@echo "  help    - Show this help message"

test:
	@echo "Running tests..."
	@if [ -f bin/run-tests.sh ]; then \
		bin/run-tests.sh; \
	else \
		echo "Test suite not yet implemented"; \
	fi

lint:
	@echo "Running ShellCheck..."
	@shellcheck bin/gcloud bin/install.sh || true
	@shellcheck -s bash lib/*.zsh || true

check: lint test
	@echo "All checks complete"

install:
	@bin/install.sh
