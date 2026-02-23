#!/usr/bin/env bash
# Installation script for gcloud-switch wrapper

set -e

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SRC="$SCRIPT_DIR/gcloud"
WRAPPER_DEST="$HOME/.local/bin/gcloud"
WRAPPER_BACKUP="$HOME/.local/bin/gcloud.backup"

echo "🔧 gcloud-switch installation"
echo "=============================="
echo ""

# Check if source wrapper exists
if [[ ! -f "$WRAPPER_SRC" ]]; then
    echo -e "${RED}❌ Error: Wrapper script not found at $WRAPPER_SRC${NC}"
    exit 1
fi

# Check if /usr/bin/gcloud exists
if [[ ! -f /usr/bin/gcloud ]]; then
    echo -e "${YELLOW}⚠️  Warning: /usr/bin/gcloud not found${NC}"
    echo "   The wrapper script expects the real gcloud CLI at /usr/bin/gcloud"
    echo "   Please install the Google Cloud SDK first:"
    echo "   https://cloud.google.com/sdk/docs/install"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Ensure ~/.local/bin exists
if [[ ! -d "$HOME/.local/bin" ]]; then
    echo "Creating directory: $HOME/.local/bin"
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$HOME/.local/bin"
    fi
fi

# Backup existing wrapper if it exists
if [[ -f "$WRAPPER_DEST" ]]; then
    echo -e "${YELLOW}⚠️  Existing wrapper found at $WRAPPER_DEST${NC}"
    if [[ "$DRY_RUN" == false ]]; then
        cp "$WRAPPER_DEST" "$WRAPPER_BACKUP"
        echo "   Backed up to: $WRAPPER_BACKUP"
    else
        echo "   [DRY RUN] Would backup to: $WRAPPER_BACKUP"
    fi
fi

# Copy wrapper script
echo "Installing wrapper script..."
if [[ "$DRY_RUN" == false ]]; then
    cp "$WRAPPER_SRC" "$WRAPPER_DEST"
    chmod +x "$WRAPPER_DEST"
    echo -e "${GREEN}✅ Installed wrapper to: $WRAPPER_DEST${NC}"
else
    echo "[DRY RUN] Would copy $WRAPPER_SRC to $WRAPPER_DEST"
fi

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Warning: $HOME/.local/bin is not in your PATH${NC}"
    echo "   Add this to your ~/.zshrc or ~/.bashrc:"
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Test the wrapper
if [[ "$DRY_RUN" == false ]]; then
    echo ""
    echo "Testing wrapper..."
    if command -v gcloud &>/dev/null; then
        WRAPPER_PATH=$(command -v gcloud)
        if [[ "$WRAPPER_PATH" == "$WRAPPER_DEST" ]]; then
            echo -e "${GREEN}✅ Wrapper is correctly prioritised in PATH${NC}"
        else
            echo -e "${YELLOW}⚠️  Warning: gcloud resolves to $WRAPPER_PATH${NC}"
            echo "   Expected: $WRAPPER_DEST"
            echo "   Make sure $HOME/.local/bin is early in your PATH"
        fi
    else
        echo -e "${RED}❌ gcloud command not found${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Reload your shell or run: source ~/.zshrc"
echo "2. Test with: gcloud-switch"
echo "3. Set up ADC for a config: gcloud-setup-adc <config-name>"
echo ""
