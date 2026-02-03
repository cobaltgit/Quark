import std/[json, os, strutils, strformat]

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
      CC='zig cc -target arm-linux-musleabihf -mcpu=cortex_a7' \
      CFLAGS='-Os -flto=thin' \
      LDFLAGS='-s -static -flto=thin -fuse-ld=lld'
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
      LDFLAGS='-s -static -flto=thin -fuse-ld=lld'
  """
  exec &"make -j {Threads}"

task evtest, "Build evtest with zig cc":
  cd(Root & "/modules/third-party/evtest")
  exec "make clean || true"
  exec "./autogen.sh"
  exec """
  ./configure --host=arm-linux-gnueabihf \
      CC="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
      CFLAGS="-Os -flto=thin" \
      LDFLAGS="-s -static -flto=thin -fuse-ld=lld"
  """
  exec &"make -j {Threads}"

task gesftpserver, "Build gesftpserver with zig cc":
  cd(Root & "/modules/third-party/gesftpserver")
  exec "make clean || true"
  exec "./autogen.sh"
  exec &"""
  ./configure --host=arm-linux-gnueabihf \
      CC="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
      LD="zig cc -target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7" \
      CFLAGS="-Os -flto=thin" \
      LDFLAGS="-s -static -flto=thin -fuse-ld=lld"
  """
  exec &"make -j {Threads}"

task dufs, "Build dufs with cargo zigbuild":
  cd(Root & "/modules/third-party/dufs")
  exec "cargo clean || true"
  exec "AWS_LC_SYS_NO_JITTER_ENTROPY=1 cargo zigbuild --target armv7-unknown-linux-musleabihf --release"

task thirdparty, "Build all third-party software":
  exec "nimble jq"
  exec "nimble evtest"
  exec "nimble dropbear"
  exec "nimble gesftpserver"
  exec "nimble dufs"
  exec "nimble syncthing"
