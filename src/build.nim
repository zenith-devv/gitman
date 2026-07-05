import std/[strformat, strutils, os, osproc, terminal, distros]
import config

let reposDir* = getHomeDir() / ".local/share/gitman/repos"
let binDir* = getHomeDir() / ".local/bin"

type StageKind* = enum
    skPrepare = "prepare"
    skBuild = "build"
    skCheck = "check"
    skInstall = "install"

proc clone*(url: string) =
    if dirExists(reposDir):
        setCurrentDir(reposDir)
    else:
        styledEcho styleBright, fgRed, &"Error: {reposDir} does not exist"

    let exitCode = execCmd(&"git clone {url}")
    if exitCode != 0:
        styledEcho styleBright, fgRed, &"Error: Failed to clone repository"
        quit(1)

proc installDepends*() =
    if loadedConfig.depends.len == 0:
        return

    styledEcho styleBright, fgCyan, "Installing needed dependencies..."

    let firstDep = loadedConfig.depends[0]
    let allDeps = loadedConfig.depends.join(" ")
    let (baseCmd, needsRoot) = foreignDepInstallCmd(firstDep)

    if baseCmd == "":
        styledEcho styleBright, fgRed, "Error: could not determine package manager for this distro"
        echo &"Install those dependencies manually: {allDeps}"
        quit(1)

    var fullCmd = baseCmd.replace(firstDep, allDeps)

    if fullCmd.contains("pacman"):
        fullCmd = fullCmd.replace("pacman -S", "pacman -S --needed --noconfirm")
    elif fullCmd.contains("zypper"):
        fullCmd = fullCmd.replace("zypper install", "zypper install -y")
    elif fullCmd.contains("apt"):
        fullCmd = fullCmd.replace("apt install", "apt install -y")
    elif fullCmd.contains("emerge"):
        fullCmd = fullCmd.replace("emerge", "emerge --noreplace")
    elif fullCmd.contains("pkg"):
        fullCmd = fullCmd.replace("pkg install", "pkg install -y")

    if needsRoot:
        fullCmd = "sudo " & fullCmd

    if execCmd(fullCmd) != 0:
        styledEcho styleBright, fgRed, "Error: failed to install dependencies"
        quit(1)

proc runStage*(cmds: seq[string], stage: StageKind) =
    if cmds.len == 0:
        return

    styledEcho styleBright, fgMagenta, &"Running stage '{$stage}'"
    for cmd in cmds:
        styledEcho styleBright, fgWhite, &"> {cmd}"
        if execCmd(cmd) != 0:
            styledEcho styleBright, fgRed, &"Error: stage '{$stage}' failed"
            quit(1)

proc buildRepo*() =
    loadConfig()
    installDepends()
    runStage(loadedConfig.prepare, skPrepare)
    runStage(loadedConfig.build, skBuild)
    runStage(loadedConfig.check, skCheck)
    runStage(loadedConfig.install, skInstall)
    if loadedConfig.name.len != 0 and loadedConfig.version.len != 0:
        styledEcho styleBright, fgGreen, &"Finished building '{loadedConfig.name} {loadedConfig.version}'"
    elif loadedConfig.name.len != 0 and loadedConfig.version.len == 0:
        styledEcho styleBright, fgGreen, &"Finished building '{loadedConfig.name}'"
    elif loadedConfig.name.len == 0 and loadedConfig.version.len == 0 or loadedConfig.name.len == 0 and loadedConfig.version.len != 0:
        styledEcho styleBright, fgGreen, "Finished building repo"
    

