# GCloud Switch Plugin
# Per-terminal gcloud configuration switching with session isolation

# Get plugin directory
0=${(%):-%N}
GCLOUD_SWITCH_DIR=${0:A:h}

# Source library files in order
source "${GCLOUD_SWITCH_DIR}/lib/session.zsh"
source "${GCLOUD_SWITCH_DIR}/lib/cleanup.zsh"
source "${GCLOUD_SWITCH_DIR}/lib/core.zsh"
source "${GCLOUD_SWITCH_DIR}/lib/adc.zsh"

# Quick aliases for common configurations (customize as needed)
# Example:
# alias gcloud-prod='gcloud-switch production'
# alias gcloud-dev='gcloud-switch development'
