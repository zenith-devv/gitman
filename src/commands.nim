import std/[strutils, strformat, os, terminal]
import networking, build, config, manager

proc installCmd*(repo: string) =
    let (repoUrl, repoName, isUrl) = search(repo)
    if not isUrl:
        while true:
            stdout.styledWrite(styleBright, fgWhite, "Continue installing? [Y/n]: ")
            stdout.flushFile()

            let choice = readLine(stdin).toLowerAscii()

            if choice == "y" or choice == "":
                break
            elif choice == "n":
                quit(0)
            else:
                echo &"Invalid choice: {choice}"

    clone(repoUrl)
    setCurrentDir(repoName.toLowerAscii())
    if fileExists(configName):
        buildRepo()
    else:
        styledEcho styleBright, fgYellow, &"{configName} was not found, keeping source"

proc buildCmd*() =
    buildRepo()

proc configCmd*() =
    createConfig()

proc removeCmd*(repo: string) =
    removeRepo(repo)

proc updateCmd*() =
    update()

proc listCmd*() =
    listRepos()

proc searchCmd*(query: string) =
    discard search(query)