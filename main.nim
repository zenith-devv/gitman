import std/[os, terminal, strformat]
import commands

const version = "0.1"

proc printHelp() =
  styledEcho styleBright, fgCyan, &"gitman v{version} - git package manager"
  echo "Usage:"
  echo "  gitman <command> [arguments]\n"
  echo "Commands:"
  echo "  install <package>  Installs a package"
  echo "  remove <package>   Removes an installed package"
  echo "  build              Builds a package using gitman.yaml"
  echo "  update             Pulls changes and rebuilds all packages"
  echo "  list               Lists all installed packages"
  echo "  search <query>     Searches for a package"
  echo "  help               Displays this help message"

proc main() =
    if paramCount() == 0:
        printHelp()
        quit(0)

    let command = paramStr(1)
    let package = if paramCount() >= 2: paramStr(2) else: ""

    case command
    of "install":
        installCmd(package)

    of "remove":
        removeCmd(package)

    of "build":
        buildCmd()

    of "update":
        updateCmd()
    
    of "config":
        configCmd()

    of "list":
        listCmd()

    of "search":
        searchCmd(package)

    of "help", "-h", "--help":
        printHelp()

    else:
        styledEcho styleBright, fgRed, &"Error: Unknown command '{command}'"
        quit(1)

if isMainModule:
    main()