import std/[strformat, strutils, os, osproc, terminal]
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

proc showDepends*() =
    if loadedConfig.depends.len == 0:
        return

    styledEcho styleBright, fgYellow, "Needed dependencies:\n"

    for depend in loadedConfig.depends:
        echo &"  - {depend}\n"
    
    while true:
        stdout.styledWrite(styleBright, fgWhite, "Proceed building? [Y/n]: ")
        stdout.flushFile()

        let choice = readLine(stdin).toLowerAscii()

        if choice == "y" or choice == "":
            break
        elif choice == "n":
            quit(0)
        else:
            echo &"Invalid choice: {choice}"

proc runStage*(cmds: seq[string], stage: StageKind): bool =
    if cmds.len == 0:
        return false

    styledEcho styleBright, fgMagenta, &"Running stage {$stage}"
    for cmd in cmds:
        let trimmed = cmd.strip()
        styledEcho styleBright, fgWhite, &"> {trimmed}"
        
        if trimmed.startsWith("cd "):
            let targetDir = trimmed["cd ".len .. ^1].strip()
            try:
                setCurrentDir(targetDir)
            except OSError:
                styledEcho styleBright, fgRed, &"Error: directory '{targetDir}' does not exist"
                quit(1)
        else:
            if execCmd(trimmed) != 0:
                styledEcho styleBright, fgRed, &"Error: stage {$stage} failed"
                quit(1)

        return true

proc buildRepo*() =
    var ranAnyStage = false
    loadConfig()
    showDepends()
    if runStage(loadedConfig.prepare, skPrepare): ranAnyStage = true
    if runStage(loadedConfig.build, skBuild):     ranAnyStage = true
    if runStage(loadedConfig.check, skCheck):     ranAnyStage = true
    if runStage(loadedConfig.install, skInstall): ranAnyStage = true

    if not ranAnyStage:
        styledEcho styleBright, fgGreen, "All stages are empty. Nothing to do."
        quit(0)
        
    if loadedConfig.name.len != 0 and loadedConfig.version.len != 0:
        styledEcho styleBright, fgGreen, &"Finished building '{loadedConfig.name} {loadedConfig.version}'"
    elif loadedConfig.name.len != 0 and loadedConfig.version.len == 0:
        styledEcho styleBright, fgGreen, &"Finished building '{loadedConfig.name}'"
    elif loadedConfig.name.len == 0 and loadedConfig.version.len == 0 or loadedConfig.name.len == 0 and loadedConfig.version.len != 0:
        styledEcho styleBright, fgGreen, "Finished building repository"
    

