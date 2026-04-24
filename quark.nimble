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
const Bins = {
  "fbscreenshot.nim": "fbscreenshot",
  "quark_hotkeyd/main.nim": "quark_hotkeyd",
  "sysjson_monitor/main.nim": "sysjson_monitor",
  "mainui_game_picker.nim": "mainui_game_picker",
  "bootlogo.nim": "bootlogo",
  "display.nim": "display",
}.toTable()
const Threads = gorge("nproc")

# Import task files
include "tasks/third_party.nims"
include "tasks/dist.nims"
include "tasks/locale.nims"

task buildBins, "Build binaries":
    for src, output in Bins:
        selfExec &"c -o:{BinDir}/{output} {srcDir}/{src}"

task cleanup, "Cleanup all":
  exec "nimble clean"
  rmDir("build")
  rmDir("dist")
  exec "rm Quark-*.zip || true"
