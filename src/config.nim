import std/[os, osproc, terminal, strformat, strutils]

const configName* = "gitman.sh"

proc createConfig*() =
    if not fileExists(configName):
        let templateContent = """#!/usr/bin/env bash

NAME="untitled"
VERSION=""

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
    :
}

check() {
    :
}

install() {
    :
}
"""
        try:
            writeFile(configName, templateContent)
            setFilePermissions(configName, {fpUserRead, fpUserWrite, fpUserExec, fpGroupRead, fpGroupExec, fpOthersRead, fpOthersExec})
            styledEcho styleBright, fgCyan, &"Created {configName} template"
        except OSError:
            styledEcho styleBright, fgRed, &"Could not create {configName}"
            quit(1)
    else:
        styledEcho styleBright, fgRed, &"{configName} already exists, will not overwrite"

proc loadConfigVar*(filePath: string, varName: string): string =
    if not fileExists(filePath):
        styledEcho styleBright, fgRed, &"{filePath} not found"
        return ""

    let bashCmd = &"bash -c 'source {quoteShell(filePath)} 2>/dev/null && echo \"${varName}\"'"
    let (output, exitCode) = execCmdEx(bashCmd)

    if exitCode == 0:
        return output.strip()

    return ""

proc loadConfigArray*(filePath: string, arrayName: string): seq[string] =
    if not fileExists(filePath):
        styledEcho styleBright, fgRed, &"{filePath} not found"
        return @[]

    let bashCmd = &"bash -c 'source {quoteShell(filePath)} 2>/dev/null && eval \"echo \\\"\\${{{arrayName}[@]}}\\\"\"'"
    let (output, exitCode) = execCmdEx(bashCmd)

    if exitCode == 0 and output.strip().len > 0:
        return output.strip().splitWhitespace()

    return @[]

