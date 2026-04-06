import std/[json, os, strutils, strformat, sequtils]

const thirdPartyBins = @[
  "modules/third-party/dropbear/dropbearmulti",
  "modules/third-party/jq/jq",
  "modules/third-party/evtest/evtest",
  "modules/third-party/gesftpserver/gesftpserver",
  "modules/third-party/dufs/target/armv7-unknown-linux-musleabihf/release/dufs",
  "modules/third-party/syncthing"
]

task syncthing, "Download and prepare latest Syncthing ARMv7 binary":
  cd(Root & "/modules/third-party")

  let apiUrl = "https://api.github.com/repos/syncthing/syncthing/releases/latest"
  let releaseData = parseJson(gorge("curl -s " & apiUrl))

  var downloadUrl, fileName: string
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
  exec "arm-linux-gnueabihf-strip -s " & binaryPath
  exec "chmod +x " & binaryPath
  mvFile(binaryPath, "syncthing")
  rmFile(fileName)
  rmDir(extractedDir)

task dropbear, "Build dropbear server with zig cc":
  cd(Root & "/modules/third-party/dropbear")
  exec "make clean || true"
  exec """
  ./configure --host=arm-linux-musleabihf --disable-zlib --enable-static \
      CC="zig cc -target arm-linux-musleabihf -mcpu=cortex_a7" \
      LD="zig cc -target arm-linux-musleabihf -mcpu=cortex_a7" \
      AR="zig ar" \
      RANLIB="zig ranlib" \
      CFLAGS='-Os -ffunction-sections -fdata-sections -fomit-frame-pointer -flto=thin' \
      LDFLAGS='-s -static -flto=thin -Wl,--gc-sections'
  """
  exec &"make -j {Threads} PROGRAMS='dropbear dropbearkey scp' MULTI=1"

task jq, "Build jq with zig cc":
  cd(Root & "/modules/third-party/jq")
  exec "make clean || true"
  exec "autoreconf -i"
  exec &"""
  ./configure --host=arm-linux-musleabihf --with-oniguruma=builtin \
      --enable-static --disable-shared \
      CC="zig cc -target arm-linux-musleabihf -mcpu=cortex_a7" \
      LD="zig cc -target arm-linux-musleabihf -mcpu=cortex_a7" \
      AR="zig ar" \
      RANLIB="zig ranlib" \
      CFLAGS='-Os -flto=thin' \
      LDFLAGS='-s -static -flto=thin'
  """
  exec &"make -j {Threads}"

task evtest, "Build evtest with zig cc":
  cd(Root & "/modules/third-party/evtest")
  exec "make clean || true"
  exec "./autogen.sh"
  exec """
  ./configure --host=arm-linux-gnueabihf \
      CC="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
      LD="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
      AR="zig ar" \
      RANLIB="zig ranlib" \
      CFLAGS="-Os -flto=thin" \
      LDFLAGS="-s -flto=thin"
  """
  exec &"make -j {Threads}"

task gesftpserver, "Build gesftpserver with zig cc":
  cd(Root & "/modules/third-party/gesftpserver")
  exec "make clean || true"
  exec "./autogen.sh"
  exec """
  ./configure --host=arm-linux-gnueabihf \
      CC="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
      LD="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
      AR="zig ar" \
      RANLIB="zig ranlib" \
      CFLAGS="-Os -flto=thin" \
      LDFLAGS="-s -flto=thin"
  """
  exec &"make -j {Threads}"

task dufs, "Build dufs with cargo zigbuild":
  putEnv("AWS_LC_SYS_NO_JITTER_ENTROPY", "1")
  cd(Root & "/modules/third-party/dufs")
  exec "cargo clean || true"
  exec "cargo zigbuild --target armv7-unknown-linux-musleabihf --release"

task thirdparty, "Build all third-party software":
  for t in @["jq", "evtest", "dropbear", "gesftpserver", "dufs", "syncthing"]:
    exec &"nimble {t} --verbose"

task buildCores, "Build RetroArch cores using Docker":
  if findExe("docker") == "":
    echo "error: docker not found"
    quit(1)

  if not fileExists(&"{Root}/scripts/cores.txt"):
    echo "error: core list not found"
    quit(1)

  let coreList = readFile(&"{Root}/scripts/cores.txt")
    .splitLines()
    .filterIt(it.strip() != "" and not it.strip().startsWith("#"))
    .join(" ")

  echo "Building cores: " & coreList

  mkDir("dist/RetroArch/.retroarch/cores")
  mkDir("dist/RetroArch/.retroarch/core_info")

  let ccacheDir = getHomeDir() / ".ccache-retroarch"
  mkDir(ccacheDir)

  try:
    exec "docker run --rm" &
      " -e CORES=\"" & coreList & "\"" &
      " -v \"$(pwd)/dist/RetroArch/.retroarch\":/output" &
      " -v \"" & ccacheDir & "\":/ccache" &
      " ghcr.io/cobaltgit/quark-core-builder:latest"
  except OSError as e:
    echo "error: core build failed"
    quit(1)

  echo "Cores built successfully"
