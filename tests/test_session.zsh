#!/usr/bin/env zsh
# Tests for session management

# Load the session library
SCRIPT_DIR="${0:A:h}"
PLUGIN_DIR="${SCRIPT_DIR:h}"
source "${PLUGIN_DIR}/lib/session.zsh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

test_session_id_generated() {
    if [[ -n "$GCLOUD_SESSION_ID" ]]; then
        echo "✓ Session ID generated: $GCLOUD_SESSION_ID"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "✗ Session ID not generated"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_session_id_format() {
    if [[ "$GCLOUD_SESSION_ID" =~ ^gcloud_[0-9]+_[0-9]+$ ]]; then
        echo "✓ Session ID has correct format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "✗ Session ID format incorrect: $GCLOUD_SESSION_ID"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_cleanup_function_exists() {
    if type gcloud_cleanup_session &>/dev/null; then
        echo "✓ Cleanup function exists"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "✗ Cleanup function not found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

test_terminal_vars_initialised() {
    if [[ -v _GCLOUD_CONFIG && -v _GCLOUD_ADC_FILE ]]; then
        echo "✓ Terminal-local variables initialised"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "✗ Terminal-local variables not initialised"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Run tests
echo "Testing session management..."
test_session_id_generated
test_session_id_format
test_cleanup_function_exists
test_terminal_vars_initialised

# Summary
echo ""
echo "Session tests: $TESTS_PASSED passed, $TESTS_FAILED failed"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
else
    exit 0
fi
