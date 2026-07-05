#!/bin/bash
mkdir -p ~/.local/share/gitman/repos
nim c -d:ssl -d:release -o:$HOME/.local/bin/gitman src/main.nim  
