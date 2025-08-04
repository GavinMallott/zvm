#!/bin/bash

set -euo pipefail

TARGET_DIR="$HOME/.zvm"
EXE_PATH="$HOME/.local/bin"
BUILD_NAME="zig-out/bin/zvm"
EXE_NAME="$HOME/.zvm/bin/zvm"

echo "Installing ZVM"

if [ ! -d "$TARGET_DIR/bin" ]; then
    echo "Creating directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR/bin"
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Creating directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

if [ ! -d "$HOME/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
fi

rm -f "$EXE_NAME"
cp "$BUILD_NAME" "$EXE_NAME"

LINK_PATH="$HOME/.local/bin/zvm"

if [ -e "$LINK_PATH" ] || [ -L "$LINK_PATH" ]; then
    echo "Purging outdated link."
    rm -f "$LINK_PATH"
fi

echo "Creating symlink: $EXE_NAME -> $EXE_PATH"

ln -sf "$EXE_NAME" "$EXE_PATH"

echo "ZVM Installed."
