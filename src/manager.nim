import std/[strformat, strutils, os, osproc, terminal]
import build, config

proc removeRepo*(repoName: string) =
    if repoName == "":
        styledEcho styleBright, fgRed, "No repo specified"
        quit(1)

    let lowerTarget = repoName.toLowerAscii()
    var foundPath = ""

    for kind, path in walkDir(reposDir):
        if kind in {pcDir, pcLinkToDir}:
            let dirName = path.extractFilename()
            if dirName.toLowerAscii() == lowerTarget:
                foundPath = path
                break

    if foundPath != "" and dirExists(foundPath):
        let actualName = foundPath.extractFilename()
        while true:
            stdout.styledWrite(styleBright, fgWhite, &"Confirm removing '{actualName}' [Y/n]: ")
            stdout.flushFile()

            let choice = readLine(stdin).toLowerAscii()

            if choice == "y" or choice == "":
                break
            elif choice == "n":
                quit(0)
            else:
                echo &"Invalid choice: {choice}"

        styledEcho styleBright, fgCyan, &"Removing source: {actualName}"
        removeDir(foundPath)
        styledEcho styleBright, fgGreen, &"Successfully removed '{actualName}'"
    else:
        styledEcho styleBright, fgRed, &"'{repoName}' was not found"
        quit(1)

proc update*() =
    if not dirExists(reposDir):
        styledEcho styleBright, fgRed, &"{reposDir} was not found"
        return

    styledEcho styleBright, fgCyan, "Updating repositories..."
    for repoPath in walkDirs(reposDir / "*"):
        let repoName = extractFilename(repoPath)

        if repoName == "gitman":
            continue

        styledEcho styleBright, fgCyan, &"Entering '{repoName}'"
        setCurrentDir(repoPath)

        let oldCommit = execProcess("git rev-parse HEAD").strip()
        let gitStatus = execCmd("git pull")

        if gitStatus != 0:
            styledEcho styleBright, fgYellow, &"Could not pull '{repoName}'. Skipping"
            continue

        let newCommit = execProcess("git rev-parse HEAD").strip()
        if oldCommit == newCommit:
            styledEcho styleBright, fgCyan, "No need to rebuild."
            continue

        if fileExists(&"{configName}"):
            buildRepo()
        else:
            styledEcho styleBright, fgYellow, &"{configName} was not found, source updated"

    styledEcho styleBright, fgGreen, "Finished updating repos"

proc updateGitman*() =
    if not dirExists(reposDir):
        styledEcho styleBright, fgRed, &"{reposDir} was not found"
        return

    setCurrentDir(reposDir)
    styledEcho styleBright, fgCyan, "Updating gitman..."
    setCurrentDir("gitman")

    let oldCommit = execProcess("git rev-parse HEAD").strip()
    let gitStatus = execCmd("git pull")

    if gitStatus != 0:
        styledEcho styleBright, fgRed, "failed to pull newest commit"

    let newCommit = execProcess("git rev-parse HEAD").strip()
    if oldCommit == newCommit:
        styledEcho styleBright, fgCyan, "No need to rebuild."
    else:
        if fileExists(&"{configName}"):
            buildRepo()
        else:
            styledEcho styleBright, fgYellow, &"{configName} was not found, source updated"

    styledEcho styleBright, fgGreen, "Finished updating gitman"


proc listRepos*() =
    if not dirExists(reposDir):
        styledEcho styleBright, fgRed, &"{reposDir} was not found"
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

proc openShell*() =
    let userShell = getEnv("SHELL", "/bin/bash")
    discard execCmd(userShell)

proc enterRepo*(repoName: string): bool =
    let target = repoName.toLowerAscii()
    for repoPath in walkDirs(reposDir / "*"):
        let foundRepo = extractFilename(repoPath)
        if foundRepo.toLowerAscii().contains(target):
            styledEcho styleBright, fgCyan, &"Entering '{foundRepo}'"
            setCurrentDir(reposDir / foundRepo)
            return true

    styledEcho styleBright, fgRed, &"'{repoName}' was not found"
    return false
