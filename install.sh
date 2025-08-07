#!/bin/bash

set -euo pipefail

TARGET_DIR="$HOME/.zvm"
EXE_PATH="$HOME/.local/bin"
BUILD_NAME="zig-out/bin/zvm"
EXE_NAME="$TARGET_DIR/bin/zvm"
LINK_PATH="$EXE_PATH/zvm"

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

echo "Replacing ~/.zvm/bin/zvm"
rm -f "$EXE_NAME"
cp "$BUILD_NAME" "$EXE_NAME"


echo "Replacing ~/.local/bin/zvm"
rm -f "$LINK_PATH"
ln -sf "$EXE_NAME" "$LINK_PATH"

echo "ZVM Installed."
