# ADC setup functionality for gcloud-switch plugin

# Map of short scope names to full OAuth2 scope URLs
typeset -gA _GCLOUD_SCOPE_MAP
_GCLOUD_SCOPE_MAP=(
    cloud-platform      "https://www.googleapis.com/auth/cloud-platform"
    bigquery            "https://www.googleapis.com/auth/bigquery"
    bigquery.readonly   "https://www.googleapis.com/auth/bigquery.readonly"
    compute             "https://www.googleapis.com/auth/compute"
    compute.readonly    "https://www.googleapis.com/auth/compute.readonly"
    datastore           "https://www.googleapis.com/auth/datastore"
    devstorage.full_control "https://www.googleapis.com/auth/devstorage.full_control"
    devstorage.read_only "https://www.googleapis.com/auth/devstorage.read_only"
    devstorage.read_write "https://www.googleapis.com/auth/devstorage.read_write"
    drive               "https://www.googleapis.com/auth/drive"
    drive.readonly      "https://www.googleapis.com/auth/drive.readonly"
    gmail.readonly      "https://www.googleapis.com/auth/gmail.readonly"
    gmail.send          "https://www.googleapis.com/auth/gmail.send"
    monitoring          "https://www.googleapis.com/auth/monitoring"
    monitoring.read     "https://www.googleapis.com/auth/monitoring.read"
    pubsub              "https://www.googleapis.com/auth/pubsub"
    spreadsheets        "https://www.googleapis.com/auth/spreadsheets"
    spreadsheets.readonly "https://www.googleapis.com/auth/spreadsheets.readonly"
    youtube.readonly    "https://www.googleapis.com/auth/youtube.readonly"
    youtube.upload      "https://www.googleapis.com/auth/youtube.upload"
)

# Resolve a scope argument to a full URL.
# 1. If it starts with https:// — use as-is
# 2. If it's a key in _GCLOUD_SCOPE_MAP — expand
# 3. Otherwise — auto-prefix with https://www.googleapis.com/auth/
_gcloud_resolve_scope() {
    local input=$1
    if [[ "$input" == https://* ]]; then
        echo "$input"
    elif (( ${+_GCLOUD_SCOPE_MAP[$input]} )); then
        echo "${_GCLOUD_SCOPE_MAP[$input]}"
    else
        echo "https://www.googleapis.com/auth/$input"
    fi
}

gcloud-setup-adc() {
    # Pre-scan arguments: extract browser flags, collect positional args
    local browser_flag=""
    local -a positional=()
    for arg in "$@"; do
        if [[ "$arg" == "--no-browser" ]]; then
            if [[ -n "$browser_flag" ]]; then
                echo "Error: --no-browser and --no-launch-browser are mutually exclusive"
                return 1
            fi
            browser_flag="--no-browser"
        elif [[ "$arg" == "--no-launch-browser" ]]; then
            if [[ -n "$browser_flag" ]]; then
                echo "Error: --no-browser and --no-launch-browser are mutually exclusive"
                return 1
            fi
            browser_flag="--no-launch-browser"
        else
            positional+=("$arg")
        fi
    done

    local config_name=${positional[1]}

    if [[ -z "$config_name" ]]; then
        echo "Usage: gcloud-setup-adc [--no-launch-browser|--no-browser] <config-name> [scope ...]"
        echo ""
        echo "Extra scopes are added alongside the default cloud-platform scope."
        echo ""
        echo "Options:"
        echo "  --no-launch-browser  Print a URL to open in any browser, then paste back the auth code"
        echo "  --no-browser         Use remote-bootstrap flow (requires gcloud on a second machine)"
        echo ""
        echo "Examples:"
        echo "  gcloud-setup-adc myconfig                              # cloud-platform only"
        echo "  gcloud-setup-adc myconfig youtube.readonly              # + YouTube read-only"
        echo "  gcloud-setup-adc myconfig drive.readonly pubsub         # + Drive + Pub/Sub"
        echo "  gcloud-setup-adc --no-launch-browser myconfig           # headless login (recommended)"
        echo "  gcloud-setup-adc --no-browser myconfig                  # remote-bootstrap login"
        echo ""
        echo "Available short scope names:"
        for key in ${(ko)_GCLOUD_SCOPE_MAP}; do
            printf "  %-28s %s\n" "$key" "${_GCLOUD_SCOPE_MAP[$key]}"
        done
        echo ""
        echo "Full URLs (https://...) and unlisted names are also accepted."
        echo ""
        echo "Available configurations:"
        /usr/bin/gcloud config configurations list --format="table(name,properties.core.account,properties.core.project)"
        return 1
    fi

    local extra_scopes=("${positional[@]:1}")

    echo "Setting up ADC for configuration: $config_name (bypassing session wrapper)"

    # Check for active sessions using this config
    gcloud_check_active_sessions "$config_name"

    # Get project and account using --configuration flag to avoid changing global state
    local project_id=$(/usr/bin/gcloud config get-value project --configuration="$config_name" 2>/dev/null)
    local account=$(/usr/bin/gcloud config get-value account --configuration="$config_name" 2>/dev/null)

    if [[ -z "$project_id" ]]; then
        echo "❌ No project set for configuration $config_name"
        echo "   Run: gcloud config set project YOUR_PROJECT_ID --configuration=$config_name"
        return 1
    fi

    if [[ -z "$account" ]]; then
        echo "❌ No account set for configuration $config_name"
        echo "   Run: gcloud config set account YOUR_EMAIL --configuration=$config_name"
        return 1
    fi

    # Build scope list when extra scopes are provided
    local scope_args=()
    if (( ${#extra_scopes[@]} > 0 )); then
        # Start with cloud-platform as the base scope
        local -aU resolved_scopes  # -U for unique elements
        resolved_scopes=("${_GCLOUD_SCOPE_MAP[cloud-platform]}")

        for s in "${extra_scopes[@]}"; do
            resolved_scopes+=("$(_gcloud_resolve_scope "$s")")
        done

        echo "Scopes:"
        for s in "${resolved_scopes[@]}"; do
            echo "  $s"
        done

        # Join with commas for the --scopes flag
        scope_args=("--scopes=${(j:,:)resolved_scopes}")
    fi

    # Setup ADC using environment variable instead of global configuration change
    echo "Setting up Application Default Credentials for $account..."
    local -a browser_args=()
    if [[ -n "$browser_flag" ]]; then
        browser_args+=("$browser_flag")
    fi

    if CLOUDSDK_ACTIVE_CONFIG_NAME="$config_name" /usr/bin/gcloud auth application-default login --project="$project_id" "${browser_args[@]}" "${scope_args[@]}"; then
        # Copy to config-specific location
        cp ~/.config/gcloud/application_default_credentials.json ~/.config/gcloud/adc-$config_name.json
        echo "✅ Created ADC file: ~/.config/gcloud/adc-$config_name.json"

        # Clean up session variables for this config in the current terminal only
        echo "🧹 Cleaning up session variables for $config_name in current terminal..."
        if [[ -n "$GCLOUD_SESSION_ID" ]]; then
            local current_config_var="GCLOUD_CONFIG_$GCLOUD_SESSION_ID"
            local current_adc_var="GCLOUD_ADC_$GCLOUD_SESSION_ID"

            # Use zsh syntax for indirect variable reference
            if [[ "${(P)current_config_var}" == "$config_name" ]]; then
                unset "$current_config_var"
                unset "$current_adc_var"
                unset GOOGLE_APPLICATION_CREDENTIALS
                echo "   Cleaned current session: $GCLOUD_SESSION_ID"
            fi
        fi

    else
        echo "❌ Failed to setup ADC"
        return 1
    fi

    echo "✅ ADC setup complete. Use 'gcloud-switch $config_name' to activate."
}
