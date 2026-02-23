# ADC setup functionality for gcloud-switch plugin

gcloud-setup-adc() {
    local config_name=$1

    if [[ -z "$config_name" ]]; then
        echo "Usage: gcloud-setup-adc <config-name>"
        echo "Available configurations:"
        /usr/bin/gcloud config configurations list --format="table(name,properties.core.account,properties.core.project)"
        return 1
    fi

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

    # Setup ADC using environment variable instead of global configuration change
    echo "Setting up Application Default Credentials for $account..."
    if CLOUDSDK_ACTIVE_CONFIG_NAME="$config_name" /usr/bin/gcloud auth application-default login --project="$project_id"; then
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
