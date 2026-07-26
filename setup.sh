#!/bin/bash
set -e
mkdir -p $HOME/.local/share/gitman/repos
mkdir -p $HOME/.local/bin
nimble install --depsOnly -y
nim c -f -d:release -d:ssl --hint[XCannotRaiseY]:off -o:"$HOME/.local/bin/gitman" src/main.nim
echo "Finished installing gitman. Make sure to add ~/.local/bin to your PATH."
