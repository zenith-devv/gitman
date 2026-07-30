import std/[strformat, strutils, os, osproc, terminal]
import build

proc removeRepo*(repoName: string) =
    if repoName == "":
        styledEcho styleBright, fgRed, "Error: no repo specified"
        quit(1)

    let lowerName = repoName.toLowerAscii()
    let targetBin = binDir / lowerName
    let targetRepo = reposDir / lowerName

    var removedAnything = false

    if fileExists(targetBin):
        styledEcho styleBright, fgCyan, &"Removing executable: {lowerName}"
        removeFile(targetBin)
        removedAnything = true

    if dirExists(targetRepo):
        styledEcho styleBright, fgCyan, &"Removing source: {lowerName}"
        removeDir(targetRepo)
        removedAnything = true

    if removedAnything:
        styledEcho styleBright, fgGreen, &"Successfully removed {lowerName}"
    else:
        styledEcho styleBright, fgRed, &"Error: '{lowerName}' was not found"

proc update*() =
    if not dirExists(reposDir):
        styledEcho styleBright, fgRed, &"Error: {reposDir} was not found"
        return

    styledEcho styleBright, fgCyan, "Updating repositories..."
    for repoPath in walkDirs(reposDir / "*"):
        let repoName = extractFilename(repoPath)
        styledEcho styleBright, fgCyan, &"Entering {repoName}"
        setCurrentDir(repoPath)

        styledEcho styleBright, fgWhite, "> git rev-parse HEAD"
        let oldCommit = execProcess("git rev-parse HEAD").strip()
        styledEcho styleBright, fgWhite, "> git pull"
        let gitStatus = execCmd("git pull")
        
        if gitStatus != 0:
            styledEcho styleBright, fgYellow, &"Could not pull {repoName}. Skipping"
            continue
        
        styledEcho styleBright, fgWhite, "> git rev-parse HEAD"
        let newCommit = execProcess("git rev-parse HEAD").strip()
        if oldCommit == newCommit:
            styledEcho styleBright, fgCyan, "No need to rebuild."
            continue
        
        let configPath = repoPath / "gitman.yaml" 
        if fileExists(configPath):
            buildRepo()
        else:
            styledEcho styleBright, fgYellow, "Config file was not found. Source updated."
    
    styledEcho styleBright, fgGreen, "Finished updating repos"

proc updateGitman*() =
    if not dirExists(reposDir):
        styledEcho styleBright, fgRed, &"Error: {reposDir} was not found"
        return
    
    setCurrentDir(reposDir)
    styledEcho styleBright, fgCyan, "Updating gitman..."
    setCurrentDir("gitman")

    styledEcho styleBright, fgWhite, "> git rev-parse HEAD"
    let oldCommit = execProcess("git rev-parse HEAD").strip()
    styledEcho styleBright, fgWhite, "> git pull"
    let gitStatus = execCmd("git pull")
    
    if gitStatus != 0:
        styledEcho styleBright, fgRed, "Error: failed to pull newest commit"
    
    styledEcho styleBright, fgWhite, "> git rev-parse HEAD"
    let newCommit = execProcess("git rev-parse HEAD").strip()
    if oldCommit == newCommit:
        styledEcho styleBright, fgCyan, "No need to rebuild."
    else:
        let configPath = "gitman" / "gitman.yaml" 
        if fileExists(configPath):
            buildRepo()
        else:
            styledEcho styleBright, fgYellow, "Config file was not found. Source updated."
        
    styledEcho styleBright, fgGreen, "Finished updating gitman"


proc listRepos*() =
    if not dirExists(reposDir):
        styledEcho styleBright, fgRed, &"Error: {reposDir} was not found"
        return

    styledEcho styleBright, fgCyan, "Installed repos:"
    var count = 0
  
    for repoPath in walkDirs(reposDir / "*"):
        let repoName = extractFilename(repoPath)
        styledEcho styleBright, fgWhite, &"  - {repoName}"
        inc(count)

    if count == 0:
        styledEcho styleBright, fgWhite, "No repos installed yet."
    else:
        styledEcho styleBright, fgCyan, &"\nTotal: {count} repo(s) installed."

proc enterRepo*(repoName: string) =
    let target = repoName.toLowerAscii()
    for repoPath in walkDirs(reposDir / "*"):
        let foundRepo = extractFilename(repoPath)
        let foundRepoLower = foundRepo.toLowerAscii()
        if foundRepoLower.contains(target):
            styledEcho styleBright, fgCyan, &"Entering {foundRepo}"
            let targetRepo = reposDir / foundRepo
            setCurrentDir(targetRepo)
            let userShell = getEnv("SHELL", "/bin/bash")
            discard execProcesses([userShell], options = {poParentStreams, poInteractive})
            quit(0)
    
    styledEcho styleBright, fgRed, &"Error: '{repoName}' was not found"

