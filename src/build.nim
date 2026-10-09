import std/[strformat, strutils, os, osproc, terminal, tables]
import config

let reposDir* = getHomeDir() / ".local/share/gitman/repos"
let binDir* = getHomeDir() / ".local/bin"

proc clone*(url: string) =
    if dirExists(reposDir):
        setCurrentDir(reposDir)
    else:
        styledEcho styleBright, fgRed, &"{reposDir} does not exist"

    let exitCode = execCmd(&"git clone {url}")
    if exitCode != 0:
        styledEcho styleBright, fgRed, &"Failed to clone repository"
        quit(1)

proc getNativeDistro(): string =
    if fileExists("/etc/os-release"):
        for line in lines("/etc/os-release"):
            if line.startsWith("ID="):
                return line.split("=")[1].strip(chars = {'"', '\''})
    return ""

proc installDepends*(cfg: RepoConfig) =
    let distro = $getNativeDistro()
    let (pmCmd, pmName) = case distro:
    of "debian", "ubuntu", "elementary", "zorin", "deepin", "lxle", "mint", "pop",
       "peppermint", "tails", "antix", "kali", "sparky", "parrot", "knoppix",
       "mx", "trisquel", "devuan":
        ("sudo apt-get install -y --no-reinstall ", "apt")
    of "arch", "manjaro", "artix", "endeavouros", "garuda", "antergos",
       "kaos", "blackarch", "parabola", "steamos":
        ("sudo pacman -S --noconfirm --needed ", "pacman")
    of "fedora", "rhel", "centos", "rocky", "almalinux", "ol":
        ("sudo dnf install -y ", "dnf")
    of "opensuse", "opensuse-tumbleweed", "opensuse-leap", "sles", "gecko":
        ("sudo zypper install -y --no-reinstall ", "zypper")
    of "gentoo", "sabayon":
        ("sudo emerge --verbose --noreplace ", "portage")
    of "alpine":
        ("sudo apk add ", "apk")
    of "void":
        ("sudo xbps-install -y ", "xbps")
    of "freebsd", "dragonfly", "ghostbsd":
        ("sudo pkg install -y ", "pkg")
    else:
        ("", "")

    if pmCmd.len == 0:
        styledEcho styleBright, fgRed, &"Your package manager is not supported by gitman. Please build the repo manually."
        quit(1)

    var depsSeq: seq[string] = @[]
    if cfg.dependencies.hasKey(pmName):
        depsSeq = cfg.dependencies[pmName]

    let deps = depsSeq.join(" ")

    if deps.len == 0:
        styledEcho styleBright, fgYellow, &"Nothing to install for '{pmName}'"
    else:
        styledEcho styleBright, fgCyan, &"Installing needed dependencies..."
        let fullCmd = &"{pmCmd}{deps}"
        let installDepsStatus = execCmd(fullCmd)

        if installDepsStatus != 0:
            styledEcho styleBright, fgRed, "Failed to install dependencies"
            quit(1)

proc runCommands*(cfg: RepoConfig) =
    if cfg.commands.len == 0:
        styledEcho styleBright, fgYellow, &"No commands to run in {configName}"
        return

    for idx, cmd in cfg.commands:
        styledEcho styleBright, fgWhite, &"[{idx + 1}/{cfg.commands.len}]", resetStyle, &" {cmd}"
        if cmd.contains("cd "):
            let path = cmd[3..^1].strip()
            try:
                setCurrentDir(path)
            except OSError as e:
                styledEcho styleBright, fgRed, "Error: ", resetStyle, e.msg
        else:
            let exitCode = execCmd(cmd)
            if exitCode != 0:
                styledEcho styleBright, fgRed, &"Command failed: {cmd}"
                quit(exitCode)

proc buildRepo*() =
    if not fileExists(configName):
        styledEcho styleBright, fgRed, &"{configName} not found"
        quit(1)

    let cfg = loadConfig(configName)

    installDepends(cfg)

    if cfg.name.len != 0 and cfg.version.len != 0:
        styledEcho styleBright, fgCyan, &"Building '{cfg.name} {cfg.version}'..."
    elif cfg.name.len != 0:
        styledEcho styleBright, fgCyan, &"Building '{cfg.name}'..."
    else:
        styledEcho styleBright, fgCyan, "Building repository..."

    runCommands(cfg)

    if cfg.name.len != 0 and cfg.version.len != 0:
        styledEcho styleBright, fgGreen, &"Finished building '{cfg.name} {cfg.version}'"
    elif cfg.name.len != 0:
        styledEcho styleBright, fgGreen, &"Finished building '{cfg.name}'"
    else:
        styledEcho styleBright, fgGreen, "Finished building repository"