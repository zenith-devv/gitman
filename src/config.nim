import std/[os, tables, terminal, strformat, strutils, sequtils]
export tables
import parsetoml

const configName* = "gitman.toml"

type
    RepoConfig* = object
        name*: string
        version*: string
        dependencies*: Table[string, seq[string]]
        commands*: seq[string]

proc createConfig*() =
    if not fileExists(configName):
        let defaultDeps = {
            "portage": newSeq[string](),
            "pacman": newSeq[string](),
            "apt": newSeq[string](),
            "dnf": newSeq[string](),
            "zypper": newSeq[string](),
            "apk": newSeq[string](),
            "xbps": newSeq[string](),
            "pkg": newSeq[string]()
        }.toTable

        let config = RepoConfig(
            name: "untitled",
            version: "0.1.0",
            dependencies: defaultDeps,
            commands: @[]
        )

        var lines: seq[string] = @[]

        lines.add("[package]")
        lines.add(&"name = \"{config.name}\"")
        lines.add(&"version = \"{config.version}\"")
        lines.add("")
        lines.add("[setup]")
        lines.add("commands = []")
        lines.add("")
        lines.add("[dependencies]")

        for pm, pkgs in config.dependencies.pairs:
            if pkgs.len == 0:
                lines.add(&"{pm} = []")
            else:
                let formattedPkgs = pkgs.mapIt(&"\"{it}\"").join(", ")
                lines.add(&"{pm} = [{formattedPkgs}]")

        let content = lines.join("\n") & "\n"

        try:
            writeFile(configName, content)
            styledEcho styleBright, fgCyan, &"Created {configName} template"
        except OSError as e:
            styledEcho styleBright, fgRed, &"Failed to create {configName}: {e.msg}"
            quit(1)
    else:
        styledEcho styleBright, fgRed, &"{configName} already exists, will not overwrite"

proc loadConfig*(filePath: string = configName): RepoConfig =
    if not fileExists(filePath):
        styledEcho styleBright, fgRed, &"{filePath} was not found"
        quit(1)

    var config: RepoConfig
    config.dependencies = initTable[string, seq[string]]()
    config.commands = @[]

    try:
        let tomlData = parsetoml.parseFile(filePath)
        if tomlData.hasKey("package"):
            let pkg = tomlData["package"]
            config.name = pkg["name"].getStr("untitled")
            config.version = pkg["version"].getStr("0.1.0")

        if tomlData.hasKey("setup"):
            for cmdNode in tomlData["setup"]["commands"].getElems():
                config.commands.add(cmdNode.getStr())

        if tomlData.hasKey("dependencies"):
            let deps = tomlData["dependencies"]
            for pm, pkgsNode in deps.getTable().pairs:
                var pkgList: seq[string] = @[]
                for item in pkgsNode.getElems():
                    pkgList.add(item.getStr())
                config.dependencies[pm] = pkgList

        styledEcho styleBright, fgGreen, &"Loaded {filePath}"
        return config

    except Exception as e:
        styledEcho styleBright, fgRed, &"Error reading {filePath}: {e.msg}"
        quit(1)