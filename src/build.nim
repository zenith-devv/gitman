import std/[strformat, strutils, os, osproc, terminal]
import config

let reposDir* = getHomeDir() / ".local/share/gitman/repos"
let binDir* = getHomeDir() / ".local/bin"

type
    StageKind* = enum
        skPrepare = "prepare"
        skBuild = "build"
        skCheck = "check"
        skInstall = "install"

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

proc installDepends*() =
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
    
    let deps = case pmName:
    of "apt": loadedConfig.depends.apt.join(" ")
    of "pacman": loadedConfig.depends.pacman.join(" ")
    of "dnf": loadedConfig.depends.dnf.join(" ")
    of "zypper": loadedConfig.depends.zypper.join(" ")
    of "portage": loadedConfig.depends.portage.join(" ")
    of "apk": loadedConfig.depends.apk.join(" ")
    of "xbps": loadedConfig.depends.xbps.join(" ")
    of "pkg": loadedConfig.depends.pkg.join(" ")
    else: ""

    if deps.len == 0:
        styledEcho styleBright, fgYellow, &"Depends field for '{pmName}' is empty, nothing to install"
    else:
        styledEcho styleBright, fgCyan, &"Installing needed dependencies..."
        let fullCmd = &"{pmCmd}{deps}"
        let installDepsStatus = execCmd(fullCmd)

        if installDepsStatus != 0:
            styledEcho styleBright, fgRed, "Failed to install dependencies"
            quit(1)

proc runStage*(cmds: seq[string], stage: StageKind): bool =
    if cmds.len == 0:
        return false

    styledEcho styleBright, fgMagenta, &"Running stage {$stage}"
    for cmd in cmds:
        let trimmed = cmd.strip()
        styledEcho styleBright, fgWhite, &"> {trimmed}"
        
        if trimmed.startsWith("cd "):
            let targetDir = trimmed["cd ".len .. ^1].strip()
            try:
                setCurrentDir(targetDir)
            except OSError:
                styledEcho styleBright, fgRed, &"directory '{targetDir}' does not exist"
                quit(1)
        else:
            if execCmd(trimmed) != 0:
                styledEcho styleBright, fgRed, &"stage {$stage} failed"
                quit(1)

        return true

proc buildRepo*() =
    var ranAnyStage = false
    loadConfig()
    installDepends()
    if runStage(loadedConfig.prepare, skPrepare): ranAnyStage = true
    if runStage(loadedConfig.build, skBuild):     ranAnyStage = true
    if runStage(loadedConfig.check, skCheck):     ranAnyStage = true
    if runStage(loadedConfig.install, skInstall): ranAnyStage = true

    if not ranAnyStage:
        styledEcho styleBright, fgGreen, "All stages are empty. Nothing to do."
        quit(0)
        
    if loadedConfig.name.len != 0 and loadedConfig.version.len != 0:
        styledEcho styleBright, fgGreen, &"Finished building '{loadedConfig.name} {loadedConfig.version}'"
    elif loadedConfig.name.len != 0 and loadedConfig.version.len == 0:
        styledEcho styleBright, fgGreen, &"Finished building '{loadedConfig.name}'"
    elif loadedConfig.name.len == 0 and loadedConfig.version.len == 0 or loadedConfig.name.len == 0 and loadedConfig.version.len != 0:
        styledEcho styleBright, fgGreen, "Finished building repository"
    

