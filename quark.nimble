import std/[os, strformat]

version        = "1.7.0"
author         = "cobaltgit"
description    = "Quark stock mod for TrimUI Smart"
license        = "GPL-3.0"
srcDir         = "src"
bin            = @["fbscreenshot/fbscreenshot", "quark_hotkeyd/quark_hotkeyd", "sysjson_monitor/sysjson_monitor", "mainui_game_picker/mainui_game_picker", "bootlogo/bootlogo", "display/display"]

requires "nim >= 2.0.0"
requires "nimPNG >= 0.3.1"

const Root = getCurrentDir()
const BinDir = Root / "dist" / "System" / "bin"
const Threads = gorge("nproc")

# Import task files
include "tasks/third_party.nims"
include "tasks/dist.nims"
include "tasks/locale.nims"

task buildBins, "Build binaries":
    for exe in bin:
        let binName = exe.split("/")[^1]
        selfExec &"c -o:{BinDir}/{binName} {srcDir}/{exe}.nim"

task cleanup, "Cleanup all":
  exec "nimble clean"
  rmDir("build")
  rmDir("dist")
  exec "rm Quark-*.zip || true"
