# Core gcloud-switch functionality

gcloud-switch() {
    local config_name=$1
    local adc_file="$HOME/.config/gcloud/adc-$config_name.json"

    if [[ -z "$config_name" ]]; then
        echo "Usage: gcloud-switch <config-name>"
        echo "Available configurations:"
        command gcloud config configurations list --format="table(name,properties.core.account,properties.core.project)"
        return 1
    fi

    # Check if ADC file exists
    if [[ ! -f "$adc_file" ]]; then
        echo "❌ ADC file missing: $adc_file"
        echo "   Run: gcloud-setup-adc $config_name"
        return 1
    fi

    # Set terminal-local variables and session-based environment variables
    _GCLOUD_CONFIG="$config_name"
    _GCLOUD_ADC_FILE="$adc_file"

    # Export session-specific variables for wrapper script and external tools
    export "GCLOUD_CONFIG_$GCLOUD_SESSION_ID"="$config_name"
    export "GCLOUD_ADC_$GCLOUD_SESSION_ID"="$adc_file"

    # Export GOOGLE_APPLICATION_CREDENTIALS for this session and child processes
    export GOOGLE_APPLICATION_CREDENTIALS="$adc_file"

    echo "✅ Switched to configuration: $config_name (this terminal only)"
    echo "   Config: $config_name"
    echo "   ADC: $adc_file"

    # Show project info if possible
    local project account
    project=$(gcloud config get-value project 2>/dev/null || echo "unknown")
    account=$(gcloud config get-value account 2>/dev/null || echo "unknown")
    echo "   Project: $project"
    echo "   Account: $account"
}
