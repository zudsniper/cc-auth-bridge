#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/cc-auth-bridge"
YES="${1:-}"

if [[ ! -f "$SOURCE" ]]; then
    echo "Error: cc-auth-bridge not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Pick install directory
if [[ -d "$HOME/.local/bin" ]] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
    DEST_DIR="$HOME/.local/bin"
else
    DEST_DIR="/usr/local/bin"
fi

DEST="$DEST_DIR/cc-auth-bridge"

if [[ "$YES" != "-y" && "$YES" != "--yes" ]]; then
    echo "Install cc-auth-bridge to $DEST?"
    read -rp "[Y/n] " answer
    if [[ "${answer,,}" == "n" ]]; then
        echo "Aborted."
        exit 0
    fi
fi

if [[ "$DEST_DIR" == "/usr/local/bin" ]] && [[ ! -w "$DEST_DIR" ]]; then
    sudo cp "$SOURCE" "$DEST"
    sudo chmod +x "$DEST"
else
    cp "$SOURCE" "$DEST"
    chmod +x "$DEST"
fi

echo "Installed to $DEST"

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$DEST_DIR"; then
    echo ""
    echo "Warning: $DEST_DIR is not in your PATH."
    echo "Add it with:"
    echo "  export PATH=\"$DEST_DIR:\$PATH\""
fi

echo "Done. Run 'cc-auth-bridge --help' to get started."
