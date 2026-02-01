version       = "1.7.0"
author        = "cobaltgit"
description   = "Quark stock mod for TrimUI Smart"
license       = "MIT"
srcDir        = "src"
binDir        = "build"
bin           = @["fbscreenshot/fbscreenshot", "quark_hotkeyd/quark_hotkeyd", "sysjson_monitor/sysjson_monitor"]


requires "nim >= 2.0.0"
requires "nimPNG >= 0.3.1"

import std/strformat

task dropbear, "Build dropbear server with zig cc":
    const Threads = gorge("nproc")
    cd("third-party/dropbear")
    exec "./configure --host=arm-linux-musleabihf --disable-zlib --enable-static CC='zig cc -target arm-linux-musleabihf -mcpu=cortex_a7' CFLAGS='-Os' LDFLAGS='-static'"
    exec &"make -j {Threads} PROGRAMS='dropbear dropbearkey scp' MULTI=1"

task base, "Prepare base zip for distribution":
    var zipName: string
    echo "nightly defined? ", defined(nightly)
    if defined(nightly):
        let gitHash = gorge("git rev-parse --short=8 HEAD")
        zipName = &"Quark-{gitHash}.zip"
    else:
        zipName = &"Quark-{version}-BASE.zip"

    exec "mkdir -p dist"
    exec "cp -R static/* dist/"
    exec "nimble build"
    for b in bin:
        exec &"cp {binDir}/{b} dist/System/bin/{b.split('/')[1]}"
    echo &"zip -9r {zipName} dist/*"
