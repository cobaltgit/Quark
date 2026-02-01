version        = "1.7.0"
author         = "cobaltgit"
description    = "Quark stock mod for TrimUI Smart"
license        = "MIT"
srcDir         = "src"
binDir         = "build"
bin            = @["fbscreenshot/fbscreenshot", "quark_hotkeyd/quark_hotkeyd", "sysjson_monitor/sysjson_monitor"]


requires "nim >= 2.0.0"
requires "nimPNG >= 0.3.1"

import std/[json, os, strutils, strformat]


const thirdPartyBins = @["third-party/dropbear/dropbearmulti", "third-party/jq/jq", "third-party/gesftpserver/gesftpserver", "third-party/dufs/target/armv7-unknown-linux-musleabihf/release/dufs", "third-party/syncthing"]
const Threads = gorge("nproc")
const Root = getCurrentDir()

task syncthing, "Download and prepare latest Syncthing ARMv7 binary":
  cd(Root & "/third-party")
  
  let apiUrl = "https://api.github.com/repos/syncthing/syncthing/releases/latest"
  
  let response = gorge("curl -s " & apiUrl)
  
  let releaseData = parseJson(response)
  
  var downloadUrl = ""
  var fileName = ""
  
  for asset in releaseData["assets"]:
    let name = asset["name"].getStr()
    if "linux-arm-" in name.toLower() and name.endsWith(".tar.gz"):
      downloadUrl = asset["browser_download_url"].getStr()
      fileName = name
      break
  
  if downloadUrl == "":
    echo "Error: Could not find ARMv7 Linux release"
    quit(1)
  
  echo "Found: ", fileName  
  exec "curl -L -o " & fileName & " " & downloadUrl
  
  exec "tar -xzf " & fileName
  
  let extractedDir = fileName.replace(".tar.gz", "")
  let binaryPath = extractedDir / "syncthing"

  exec "llvm-strip -s " & binaryPath
  exec "chmod +x " & binaryPath
  mvFile(binaryPath, "syncthing")
  rmFile(fileName)
  rmDir(extractedDir)

task dropbear, "Build dropbear server with zig cc":
    cd(Root & "/third-party/dropbear")
    exec "make clean || true"
    exec """
    ./configure --host=arm-linux-musleabihf --disable-zlib --enable-static \
        CC='zig cc -target arm-linux-musleabihf -mcpu=cortex_a7' \
        CFLAGS='-Os -flto=thin' \
        LDFLAGS='-s -static -flto=thin'
    """
    exec &"make -j {Threads} PROGRAMS='dropbear dropbearkey scp' MULTI=1"

task jq, "Build jq with zig cc":
    cd("third-party/jq")
    exec "make clean || true"
    exec "autoreconf -i"
    exec &"""
    ./configure --host=arm-linux-gnueabihf --with-oniguruma=builtin \
        CC="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
        LD="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
        AR="zig ar" \
        RANLIB="zig ranlib" \
        CFLAGS='-Os -flto=thin' \
        LDFLAGS='-s -flto=thin'
    """
    exec &"make -j {Threads}"

task evtest, "Build evtest with zig cc":
    cd(Root & "/third-party/evtest")
    exec "make clean || true"
    exec "./autogen.sh"
    exec """
    ./configure --host=arm-linux-gnueabihf \
        CC='zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7' \
        CFLAGS='-Os -flto=thin' \
        LDFLAGS='-s -flto=thin'
    """
    exec &"make -j {Threads}"

task gesftpserver, "Build gesftpserver with zig cc":
    cd(Root & "/third-party/gesftpserver")
    exec "make clean || true"
    exec "./autogen.sh"
    exec &"""
    ./configure --host=arm-linux-gnueabihf \
        CC="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
        LD="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
        CFLAGS='-Os -flto=thin' \
        LDFLAGS='-s -flto=thin'
    """
    exec &"make -j {Threads}"

task dufs, "Build dufs with cargo-zigbuild":
    cd(Root & "/third-party/dufs")
    exec "cross clean || true"
    exec "cross build --target armv7-unknown-linux-musleabihf --release"

task thirdparty, "Build all third-party software":
    exec "nimble jq"
    exec "nimble evtest"
    exec "nimble dropbear"
    exec "nimble gesftpserver"
    exec "nimble dufs"
    exec "nimble syncthing"

task base, "Prepare base zip for distribution":
    var zipName: string
    echo "nightly defined? ", defined(nightly)
    if defined(nightly):
        let gitHash = gorge("git rev-parse --short=8 HEAD")
        zipName = &"Quark-{gitHash}.zip"
    else:
        zipName = &"Quark-{version}-BASE.zip"

    cpDir(Root & "/static", Root & "/dist")
    exec "nimble build"
    exec "nimble thirdparty"
    for b in bin:
        cpFile(&"{Root}/{binDir}/{b}", &"dist/System/bin/{b.split('/')[^1]}")
    for tpb in thirdPartyBins:
        cpFile(&"{Root}/{tpb}", &"dist/System/bin/{tpb.split('/')[^1]}")
    cd("dist")
    exec &"zip -9r {Root}/{zipName} *"
