# Cleanup utilities for gcloud-switch plugin

# Check for active sessions using a specific config
gcloud_check_active_sessions() {
    local config_name=$1
    local active_sessions=()

    for line in $(env 2>/dev/null | grep '^GCLOUD_CONFIG_gcloud_'); do
        local var=${line%%=*}
        local value=${line#*=}
        local session_id=${var#GCLOUD_CONFIG_}

        if [[ "$value" == "$config_name" ]]; then
            local pid=${session_id##*_}
            if kill -0 "$pid" 2>/dev/null; then
                active_sessions+=("$session_id")
            fi
        fi
    done

    if [[ ${#active_sessions[@]} -gt 0 ]]; then
        echo "⚠️  Active sessions using config '$config_name':"
        for session in "${active_sessions[@]}"; do
            local pid=${session##*_}
            echo "   Session: $session (PID: $pid)"
        done
        echo "   These sessions will need to switch again after ADC setup."
        return 0
    fi
    return 1
}

# Manual cleanup function for stale sessions
gcloud-cleanup() {
    echo "🧹 Cleaning up stale gcloud session variables..."
    local cleaned=0

    for line in $(env 2>/dev/null | grep '^GCLOUD_CONFIG_gcloud_'); do
        local var=${line%%=*}
        local session_id=${var#GCLOUD_CONFIG_}
        local pid=${session_id##*_}

        # Check if the process still exists
        if ! kill -0 "$pid" 2>/dev/null; then
            unset "GCLOUD_CONFIG_$session_id"
            unset "GCLOUD_ADC_$session_id"
            echo "   Cleaned session: $session_id"
            ((cleaned++))
        fi
    done

    if [[ $cleaned -eq 0 ]]; then
        echo "   No stale sessions found"
    else
        echo "   Cleaned $cleaned stale session(s)"
    fi
}
