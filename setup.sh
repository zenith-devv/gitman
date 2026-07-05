#!/bin/bash
mkdir -p ~/.local/share/gitman/repos
nimble install --depsOnly
nim c -d:release -d:ssl -o:"$HOME/.local/bin/gitman" src/main.nim
