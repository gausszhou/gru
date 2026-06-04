#!/usr/bin/env bash
set -euo pipefail

REPO="gausszhou/gru"
INSTALL_DIR="${GRU_INSTALL:-$HOME/.local/bin}"

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

case "$OS" in
    linux|darwin) ;;
    *)
        echo "Unsupported OS: $OS"
        echo "For Windows, use: iex ((New-Object System.Net.WebClient).DownloadString('https://github.com/$REPO/releases/latest/download/install.ps1'))"
        exit 1
        ;;
esac

# Get latest version
echo "Checking latest version..."
VERSION=$(curl -sSfL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
if [ -z "$VERSION" ]; then
    echo "Failed to determine latest version"
    exit 1
fi
echo "Found gru $VERSION"

# Download and extract
ARCHIVE_NAME="gru-$OS-$ARCH.tar.gz"
URL="https://github.com/$REPO/releases/download/$VERSION/$ARCHIVE_NAME"

echo "Downloading $URL..."
mkdir -p "$INSTALL_DIR"
curl -sSfL "$URL" | tar xz -C "$INSTALL_DIR" gru
chmod +x "$INSTALL_DIR/gru"

echo "Installed gru $VERSION to $INSTALL_DIR/gru"

# Check PATH
case ":$PATH:" in
    *:"$INSTALL_DIR":*) ;;
    *)
        echo ""
        echo "NOTE: $INSTALL_DIR is not in your PATH."
        echo "Add it with: export PATH=\"\$PATH:$INSTALL_DIR\""
        echo "Or add this line to your ~/.bashrc / ~/.zshrc:"
        echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
        ;;
esac
