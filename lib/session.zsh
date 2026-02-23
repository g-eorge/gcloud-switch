# Session management for gcloud-switch plugin

# Terminal-local gcloud configuration variables
_GCLOUD_CONFIG=""
_GCLOUD_ADC_FILE=""

# Generate unique session ID for this shell
if [[ -z "$GCLOUD_SESSION_ID" ]]; then
    export GCLOUD_SESSION_ID="gcloud_$(date +%s)_$$"
fi

# Cleanup function for session variables
gcloud_cleanup_session() {
    if [[ -n "$GCLOUD_SESSION_ID" ]]; then
        unset "GCLOUD_CONFIG_$GCLOUD_SESSION_ID"
        unset "GCLOUD_ADC_$GCLOUD_SESSION_ID"
        unset GOOGLE_APPLICATION_CREDENTIALS
    fi
}

# Auto-cleanup on shell exit
trap gcloud_cleanup_session EXIT
