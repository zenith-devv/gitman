#!/bin/bash
mkdir -p ~/.local/share/gitman/repos
nimble install -y
nimble build -d:release -d:ssl --debug
mv ./main $HOME/.local/bin/gitman
