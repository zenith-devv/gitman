import std/[strformat, strutils, os, osproc, terminal]
import build

proc removeRepo*(repoName: string) =
    if repoName == "":
        styledEcho styleBright, fgRed, "Error: no package specified"
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
        styledEcho styleBright, fgWhite, "> git pull"
        let gitStatus = execCmd("git pull")

        if gitStatus != 0:
            styledEcho styleBright, fgYellow, &"Could not pull {repoName}. Skipping"
            continue

        let configPath = repoPath / "gitman.yaml" 
        if fileExists(configPath):
            buildRepo()
        else:
            styledEcho styleBright, fgYellow, "Config file was not found. Source updated."
    
    styledEcho styleBright, fgGreen, "Finished updating repos"

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
        styledEcho styleBright, fgWhite, "No packages installed yet."
    else:
        styledEcho styleBright, fgCyan, &"\nTotal: {count} package(s) installed."