import std/[os, streams, terminal, strformat], yaml

const configName* = "gitman.yaml"

type Config* = object
    name*: string
    version*: string
    depends*: seq[string]
    prepare*: seq[string]
    build*: seq[string]
    check*: seq[string]
    install*: seq[string]

var loadedConfig*: Config

proc createConfig*() =
    if not fileExists(configName):
        var cfgTemplate = Config()
        var s = newFileStream(configName, fmWrite)
        if s == nil:
            styledEcho styleBright, fgRed, &"Error: Could not create {configName}"
            quit(1)

        defer: s.close()
        Dumper().dump(cfgTemplate, s)
        styledEcho styleBright, fgCyan, &"Created {configName} template"
    else:
        styledEcho styleBright, fgRed, &"Error: {configName} already exists, will not overwrite"

proc loadConfig*(filePath: string = configName) =
    if not fileExists(filePath):
        styledEcho styleBright, fgRed, &"Error: {configName} not found at {filePath}"
        quit(1)

    var s = openFileStream(filePath, fmRead)
    if s == nil:
        styledEcho styleBright, fgRed, &"Error: Could not open {filePath}"
        quit(1)
    defer: s.close()

    try:
        yaml.load(s, loadedConfig)
    except Exception as e:
        styledEcho styleBright, fgRed, &"Error parsing {configName}: ", resetStyle, e.msg
        quit(1)

    styledEcho styleBright, fgCyan, &"Loaded {configName}"


