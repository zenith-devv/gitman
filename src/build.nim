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

proc checkNeededTools*() =
    if loadedConfig.tools.len == 0:
        return

    styledEcho styleBright, fgCyan, "Checking needed tools..."

    for tool in loadedConfig.tools:
        echo &"  Looking for {tool}..."
        let res = findExe(tool)
        echo &"    {res}"
        if res == "":
            styledEcho styleBright, fgRed, &"Error: {tool} was not found installed"
            quit(1)

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
    checkNeededTools()
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
    

