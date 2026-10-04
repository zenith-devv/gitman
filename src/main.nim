import std/[os, terminal, strformat]
import commands

const version = "0.10.1"

proc printHelp() =
    styledEcho styleBright, fgCyan, &"gitman v{version} - git repo manager\n"
    echo "Usage:"
    echo "  gitman <command> [arguments]\n"
    echo "Commands:"
    echo "  cl, clone <repo>        Clones a repo"
    echo "  rm, remove <repo>       Removes a cloned repo"
    echo "  b, build                Builds a repo using gitman.yaml"
    echo "  up, update              Pulls changes and rebuilds all repos"
    echo "  ls, list                Lists all cloned repos"
    echo "  s, search <query>       Searches for a repo"
    echo "  e, enter <repo>         Enter the directory of the cloned repo"
    echo "  cfg, config             Create gitman.yaml template"
    echo "  h, help                 Displays this help message"

proc main() =
    if paramCount() == 0:
        printHelp()
        quit(0)

    let command = paramStr(1)
    let repo = if paramCount() >= 2: paramStr(2) else: ""

    case command
    of "cl", "clone":
        cloneCmd(repo)
    of "rm", "remove":
        removeCmd(repo)
    of "b", "build":
        buildCmd()
    of "up", "update":
        updateCmd()
    of "cfg", "config":
        configCmd()
    of "ls", "list":
        listCmd()
    of "s", "search":
        searchCmd(repo)
    of "e", "enter":
        enterCmd(repo)
    of "h", "help":
        printHelp()
    else:
        styledEcho styleBright, fgRed, &"Unknown command '{command}'"
        quit(1)

if isMainModule:
    main()
