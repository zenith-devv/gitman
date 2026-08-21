#!/bin/bash
set -e

REPOS_DIR="$HOME/.local/share/gitman/repos"
TARGET_SRC="$REPOS_DIR/gitman"
BIN_DIR="$HOME/.local/bin"

SRC_DIR="$(pwd)"

mkdir -p "$REPOS_DIR"
mkdir -p "$BIN_DIR"

nim c -f -d:release -d:ssl -o:"$BIN_DIR/gitman" src/main.nim

if [ "$SRC_DIR" != "$TARGET_SRC" ]; then
    rm -rf "$TARGET_SRC"
    cd ..
    mv "$SRC_DIR" "$TARGET_SRC"
    cd "$TARGET_SRC"
    echo "Finished installing gitman. Sources are in $REPOS_DIR."
    echo "Make sure to add ~/.local/bin to your PATH."
    exit 0
fi

