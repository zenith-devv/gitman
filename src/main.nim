import std/[os, terminal, strformat]
import commands

const version = "0.9.4"

proc printHelp() =
  styledEcho styleBright, fgCyan, &"gitman v{version} - git repo manager\n"
  echo "Usage:"
  echo "  gitman <command> [arguments]\n"
  echo "Commands:"
  echo "  cl <repo>        Clones a repo"
  echo "  rm <repo>        Removes a cloned repo"
  echo "  b                Builds a repo using gitman.yaml"
  echo "  up               Pulls changes and rebuilds all repos"
  echo "  ls               Lists all cloned repos"
  echo "  s <query>        Searches for a repo"
  echo "  cd <repo>        Enter the directory of the cloned repo"
  echo "  h                Displays this help message"

proc main() =
    if paramCount() == 0:
        printHelp()
        quit(0)

    let command = paramStr(1)
    let repo = if paramCount() >= 2: paramStr(2) else: ""

    case command
    of "cl":
        cloneCmd(repo)
    of "rm":
        removeCmd(repo)
    of "b":
        buildCmd()
    of "up":
        updateCmd()
    of "cfg":
        configCmd()
    of "ls":
        listCmd()
    of "s":
        searchCmd(repo)
    of "cd":
        enterCmd(repo)
    of "h":
        printHelp()
    else:
        styledEcho styleBright, fgRed, &"Unknown command '{command}'"
        quit(1)

if isMainModule:
    main()