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

    let arrayVarName = &"DEPENDS_{pmName.toUpperAscii()}"
    let depsSeq = loadConfigArray("gitman.sh", arrayVarName)
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

proc runStage*(stage: StageKind): bool =
    let checkCmd = &"bash -c 'source gitman.sh 2>/dev/null && declare -f {$stage} >/dev/null'"
    if execCmd(checkCmd) != 0:
        return false

    let runCmd = &"bash -c 'set -e; source gitman.sh; set -x; {$stage}'"
    let exitCode = execCmd(runCmd)

    if exitCode != 0:
        styledEcho styleBright, fgRed, &"{$stage} failed"
        quit(1)

    return true

proc buildRepo*() =
    let name = loadConfigVar("gitman.sh", "NAME")
    let version = loadConfigVar("gitman.sh", "VERSION")

    if not fileExists("gitman.sh"):
        styledEcho styleBright, fgRed, "gitman.sh not found"
        quit(1)

    installDepends()

    styledEcho styleBright, fgCyan, &"Building '{name} {version}'"
    var ranAnyStage = false
    if runStage(skPrepare): ranAnyStage = true
    if runStage(skBuild):   ranAnyStage = true
    if runStage(skCheck):   ranAnyStage = true
    if runStage(skInstall): ranAnyStage = true

    if not ranAnyStage:
        styledEcho styleBright, fgYellow, "All stages are empty or missing. Nothing to do."
        quit(0)

    if name.len != 0 and version.len != 0:
        styledEcho styleBright, fgGreen, &"Finished building '{name} {version}'"
    elif name.len != 0:
        styledEcho styleBright, fgGreen, &"Finished building '{name}'"
    else:
        styledEcho styleBright, fgGreen, "Finished building repository"