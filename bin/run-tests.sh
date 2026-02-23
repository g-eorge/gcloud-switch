#!/usr/bin/env bash
# Test runner for gcloud-switch plugin

set -e

echo "🧪 Running gcloud-switch tests..."
echo "================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$PLUGIN_DIR/tests"

# Check if test directory exists
if [[ ! -d "$TEST_DIR" ]]; then
    echo "❌ Test directory not found: $TEST_DIR"
    exit 1
fi

# Track results
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Run each test file
for test_file in "$TEST_DIR"/test_*.zsh "$TEST_DIR"/test_*.sh; do
    if [[ -f "$test_file" ]]; then
        echo "Running $(basename "$test_file")..."
        TESTS_RUN=$((TESTS_RUN + 1))

        if [[ "$test_file" == *.zsh ]]; then
            if zsh "$test_file"; then
                TESTS_PASSED=$((TESTS_PASSED + 1))
                echo "✅ PASSED"
            else
                TESTS_FAILED=$((TESTS_FAILED + 1))
                echo "❌ FAILED"
            fi
        else
            if bash "$test_file"; then
                TESTS_PASSED=$((TESTS_PASSED + 1))
                echo "✅ PASSED"
            else
                TESTS_FAILED=$((TESTS_FAILED + 1))
                echo "❌ FAILED"
            fi
        fi
        echo ""
    fi
done

# Summary
echo "================================"
echo "Test Summary:"
echo "  Total: $TESTS_RUN"
echo "  Passed: $TESTS_PASSED"
echo "  Failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "❌ Some tests failed"
    exit 1
else
    echo "✅ All tests passed!"
    exit 0
fi
