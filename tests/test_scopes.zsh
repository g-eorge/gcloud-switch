#!/usr/bin/env zsh
# Tests for scope resolution

# Load the ADC library (which defines the scope map and resolver)
SCRIPT_DIR="${0:A:h}"
PLUGIN_DIR="${SCRIPT_DIR:h}"
source "${PLUGIN_DIR}/lib/adc.zsh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

assert_eq() {
    local description=$1 expected=$2 actual=$3
    if [[ "$actual" == "$expected" ]]; then
        echo "✓ $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ $description"
        echo "  expected: $expected"
        echo "  actual:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# --- _gcloud_resolve_scope tests ---

test_resolve_known_short_name() {
    local result=$(_gcloud_resolve_scope "youtube.readonly")
    assert_eq "Resolves known short name (youtube.readonly)" \
        "https://www.googleapis.com/auth/youtube.readonly" "$result"
}

test_resolve_another_known_name() {
    local result=$(_gcloud_resolve_scope "drive.readonly")
    assert_eq "Resolves known short name (drive.readonly)" \
        "https://www.googleapis.com/auth/drive.readonly" "$result"
}

test_resolve_full_url_passthrough() {
    local url="https://www.googleapis.com/auth/calendar.readonly"
    local result=$(_gcloud_resolve_scope "$url")
    assert_eq "Full URL passed through unchanged" "$url" "$result"
}

test_resolve_custom_full_url() {
    local url="https://example.com/custom/scope"
    local result=$(_gcloud_resolve_scope "$url")
    assert_eq "Custom full URL passed through unchanged" "$url" "$result"
}

test_resolve_unknown_name_auto_prefix() {
    local result=$(_gcloud_resolve_scope "calendar.readonly")
    assert_eq "Unknown name auto-prefixed" \
        "https://www.googleapis.com/auth/calendar.readonly" "$result"
}

test_resolve_cloud_platform() {
    local result=$(_gcloud_resolve_scope "cloud-platform")
    assert_eq "Resolves cloud-platform" \
        "https://www.googleapis.com/auth/cloud-platform" "$result"
}

# --- Scope map tests ---

test_scope_map_has_entries() {
    local count=${#_GCLOUD_SCOPE_MAP}
    if (( count >= 20 )); then
        echo "✓ Scope map has $count entries (>= 20)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ Scope map has $count entries (expected >= 20)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_scope_map_includes_cloud_platform() {
    if (( ${+_GCLOUD_SCOPE_MAP[cloud-platform]} )); then
        echo "✓ Scope map includes cloud-platform"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ Scope map missing cloud-platform"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# --- Deduplication test ---

test_cloud_platform_dedup() {
    # Simulate the dedup logic from gcloud-setup-adc
    local -aU resolved_scopes
    resolved_scopes=("${_GCLOUD_SCOPE_MAP[cloud-platform]}")
    resolved_scopes+=("$(_gcloud_resolve_scope "cloud-platform")")
    resolved_scopes+=("$(_gcloud_resolve_scope "youtube.readonly")")

    if (( ${#resolved_scopes} == 2 )); then
        echo "✓ cloud-platform deduplicated (2 unique scopes)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ Deduplication failed: got ${#resolved_scopes} scopes, expected 2"
        for s in "${resolved_scopes[@]}"; do
            echo "  - $s"
        done
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

test_cloud_platform_always_first() {
    local -aU resolved_scopes
    resolved_scopes=("${_GCLOUD_SCOPE_MAP[cloud-platform]}")
    resolved_scopes+=("$(_gcloud_resolve_scope "drive")")

    if [[ "${resolved_scopes[1]}" == "https://www.googleapis.com/auth/cloud-platform" ]]; then
        echo "✓ cloud-platform is first scope"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ cloud-platform is not first scope: ${resolved_scopes[1]}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Run tests
echo "Testing scope resolution..."
test_resolve_known_short_name
test_resolve_another_known_name
test_resolve_full_url_passthrough
test_resolve_custom_full_url
test_resolve_unknown_name_auto_prefix
test_resolve_cloud_platform
test_scope_map_has_entries
test_scope_map_includes_cloud_platform
test_cloud_platform_dedup
test_cloud_platform_always_first

# Summary
echo ""
echo "Scope tests: $TESTS_PASSED passed, $TESTS_FAILED failed"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
else
    exit 0
fi
