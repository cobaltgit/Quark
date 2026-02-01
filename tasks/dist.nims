import std/[os, strutils, strformat]

task base, "Prepare base zip for distribution":
  var zipName: string
  var ver: string
  
  let isNightly = getEnv("NIGHTLY") == "1"
  
  if isNightly:
    echo "Building nightly release"
    ver = gorge("git rev-parse --short=8 HEAD")
    zipName = &"Quark-{ver}-BASE.zip"
  else:
    echo "Building stable release"
    ver = version
    zipName = &"Quark-v{ver}-BASE.zip"

  rmDir("dist")
  cpDir(Root & "/static", Root & "/dist")
  
  # Update locales in dist AFTER copying
  exec "nim e scripts/updateLocales.nims " & ver & " dist/trimui/res/lang"
  
  exec "nimble build"
  for b in bin:
    mvFile(&"{Root}/{binDir}/{b}", &"dist/System/bin/{b.split('/')[^1]}")
  
  exec "nimble thirdparty"
  for tpb in thirdPartyBins:
    mvFile(&"{Root}/{tpb}", &"dist/System/bin/{tpb.split('/')[^1]}")
  
  cd("dist")
  exec &"zip -9r {Root}/{zipName} *"

task updater, "Prepare updater package":
  let isNightly = getEnv("NIGHTLY") == "1"
  var
    baseZip: string
    updateZip: string
    updaterZip: string
  
  if isNightly:
    let ver = gorge("git rev-parse --short=8 HEAD")
    updateZip = &"Quark_Update_{ver}.zip"
    baseZip = &"Quark-{ver}-BASE.zip"
    updaterZip = &"Quark-{ver}-Updater.zip"
  else:
    updateZip = &"Quark_Update_v{version}.zip"
    baseZip = &"Quark-v{version}-BASE.zip"
    updaterZip = &"Quark-v{version}-Updater.zip"
  
  if not fileExists(baseZip):
    exec "nimble base"

  cpFile(baseZip, updateZip)
  exec &"zip --delete {updateZip} 'Updater/*'"
  
  let tempDir = "dist_updater_temp"
  rmDir(tempDir)
  mkDir(tempDir & "/Apps")
  
  cpDir("dist/Apps/QuarkUpdater", &"{tempDir}/Apps/QuarkUpdater")
  cpDir("dist/Updater", &"{tempDir}/Updater")
  mvFile(updateZip, &"{tempDir}/{updateZip}")
  
  cd(tempDir)
  exec &"zip -9r {Root}/{updaterZip} *"
  
  cd(Root)
  rmDir(tempDir)

task full, "Prepare base, full and updater zips for release":
  var
    baseZip: string
    fullZip: string
  let isNightly = getEnv("NIGHTLY") == "1"
  
  if isNightly:
    let ver = gorge("git rev-parse --short=8 HEAD")
    baseZip = &"Quark-{ver}-BASE.zip"
    fullZip = &"Quark-{ver}-FULL.zip"
  else:
    baseZip = &"Quark-v{version}-BASE.zip"
    fullZip = &"Quark-v{version}-FULL.zip"
  
  if not fileExists(baseZip):
    exec "nimble updater"
  
  echo "Creating full zip from base zip..."
  cpFile(baseZip, fullZip)
  
  let tempDir = "dist_full_temp"
  rmDir(tempDir)
  mkDir(tempDir)
  
  echo "Copying gluons into zip..."
  for category in @["Systems", "Themes"]:
    let categoryPath = Root & "/modules/gluons/" & category
    if dirExists(categoryPath):
      cd(categoryPath)
      for d in listDirs("."):
        let gluonPath = &"{categoryPath}/{d}/mnt/SDCARD"
        if dirExists(gluonPath):
          cd(gluonPath)
          exec &"zip -9ur {Root}/{fullZip} *"
  
  cd(Root)
  rmDir(tempDir)
  echo "Full zip created: ", fullZip
