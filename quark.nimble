import std/[os, strformat]

version        = "1.7.0"
author         = "cobaltgit"
description    = "Quark stock mod for TrimUI Smart"
license        = "GPL-3.0"
srcDir         = "src"

requires "nim >= 2.0.0"
requires "nimPNG >= 0.3.1"

const Root = getCurrentDir()
const BinDir = Root / "dist" / "System" / "bin"
const Threads = gorge("nproc")

# Import task files
include "tasks/third_party.nims"
include "tasks/dist.nims"
include "tasks/locale.nims"

task buildBins, "Build Quark binaries":
    for kind, path in walkDir(srcDir):
        case kind
        of pcFile:
            let parts = splitFile(path)
            if parts.ext == ".nim"
                echo fmt"compiling {parts.dir}/{parts.name}{parts.ext} to binary {BinDir}/{parts.name}"
                selfExec fmt"c -o:{BinDir}/{parts.name} {parts.dir}/{parts.name}{parts.ext}"
        of pcDir:
            let entryPath = path / "main.nim"
            if fileExists(entryPath):
                let binName = entryPath.parentDir().lastPathPart()
                echo fmt"compiling {entryPath} to binary {BinDir}/{binName}"
                selfExec fmt"c -o:{BinDir}/{binName} {entryPath}"
        else:
            discard

task cleanup, "Cleanup all":
  exec "nimble clean"
  rmDir("build")
  rmDir("dist")
  exec "rm Quark-*.zip || true"
