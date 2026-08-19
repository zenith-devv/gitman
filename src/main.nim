import std/[os, terminal, strformat]
import commands

const version = "0.8.1"

proc printHelp() =
  styledEcho styleBright, fgCyan, &"gitman v{version} - git repo manager\n"
  echo "Usage:"
  echo "  gitman <command> [arguments]\n"
  echo "Commands:"
  echo "  install <repo>     Installs a repo"
  echo "  remove <repo>      Removes an installed repo"
  echo "  build              Builds a repo using gitman.yaml"
  echo "  update             Pulls changes and rebuilds all repos"
  echo "  list               Lists all installed repos"
  echo "  search <query>     Searches for a repo"
  echo "  enter <repo>       Enter the directory of the installed repo"
  echo "  self-update        Pull the newest commit of gitman and rebuild it"
  echo "  help               Displays this help message"

proc main() =
    if paramCount() == 0:
        printHelp()
        quit(0)

    let command = paramStr(1)
    let repo = if paramCount() >= 2: paramStr(2) else: ""

    case command
    of "install":
        installCmd(repo)
    of "remove":
        removeCmd(repo)
    of "build":
        buildCmd()
    of "update":
        updateCmd()
    of "config":
        configCmd()
    of "list":
        listCmd()
    of "search":
        searchCmd(repo)
    of "enter":
        enterCmd(repo)
    of "self-update":
        selfUpdateCmd()
    of "help":
        printHelp()
    else:
        styledEcho styleBright, fgRed, &"Unknown command '{command}'"
        quit(1)

if isMainModule:
    main()