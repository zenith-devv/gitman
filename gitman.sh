#!/usr/bin/env bash

NAME="gitman"
VERSION="0.9.3"

DEPENDS_PORTAGE=()
DEPENDS_PACMAN=()
DEPENDS_APT=()
DEPENDS_DNF=()
DEPENDS_ZYPPER=()
DEPENDS_APK=()
DEPENDS_XBPS=()
DEPENDS_PKG=()

prepare() {
    :
}

build() {
    nim c -f -d:release -d:ssl -o:"$HOME/.local/bin/gitman" src/main.nim
}

check() {
    :
}

install() {
    :
}
