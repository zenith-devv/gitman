import std/[os, terminal, strformat]
import commands

const version = "0.9.3"

proc printHelp() =
  styledEcho styleBright, fgCyan, &"gitman v{version} - git repo manager\n"
  echo "Usage:"
  echo "  gitman <command> [arguments]\n"
  echo "Commands:"
  echo "  clone, cl <repo>       clones a repo"
  echo "  remove, rm <repo>      Removes a cloned repo"
  echo "  build, b               Builds a repo using gitman.yaml"
  echo "  update, up             Pulls changes and rebuilds all repos"
  echo "  list, ls               Lists all cloned repos"
  echo "  search, s <query>      Searches for a repo"
  echo "  enter, e <repo>        Enter the directory of the cloned repo"
  echo "  help, h                Displays this help message"

proc main() =
    if paramCount() == 0:
        printHelp()
        quit(0)

    let command = paramStr(1)
    let repo = if paramCount() >= 2: paramStr(2) else: ""

    case command
    of "clone", "cl":
        cloneCmd(repo)
    of "remove", "rm":
        removeCmd(repo)
    of "build", "b":
        buildCmd()
    of "update", "up":
        updateCmd()
    of "config", "cfg":
        configCmd()
    of "list", "ls":
        listCmd()
    of "search", "s":
        searchCmd(repo)
    of "enter", "e":
        enterCmd(repo)
    of "help", "h":
        printHelp()
    else:
        styledEcho styleBright, fgRed, &"Unknown command '{command}'"
        quit(1)

if isMainModule:
    main()