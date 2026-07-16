#!/bin/bash
mkdir -p ~/.local/share/gitman/repos
nimble install --depsOnly -y
nim c -d:release -d:ssl -o:"$HOME/.local/bin/gitman" src/main.nim
echo "Finished installing gitman. Make sure to add ~/.local/bin to your PATH."
