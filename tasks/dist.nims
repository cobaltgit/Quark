import std/[strutils, strformat]

proc isNightly(): bool = getEnv("NIGHTLY") == "1"

proc getBuildVer(): string =
  if isNightly(): gorge("git rev-parse --short=8 HEAD")
  else: version

proc getZipName(label, ver: string): string =
  let prefix = if isNightly(): ver else: "v" & ver
  &"Quark-{prefix}-{label}.zip"

proc stageAndZip(tempDir, zipTarget: string, populateFn: proc()) =
  rmDir(tempDir)
  mkDir(tempDir)
  populateFn()
  cd(tempDir)
  exec &"zip -9r {Root}/{zipTarget} * -x '*.gitkeep'"
  cd(Root)
  rmDir(tempDir)

task base, "Prepare base zip for distribution":
  let ver = getBuildVer()
  let zipName = getZipName("BASE", ver)

  if isNightly(): echo "Building nightly release"
  else: echo "Building stable release"

  rmDir("dist")
  cpDir(Root & "/static", Root & "/dist")

  let coresStaging = Root & "/retroarch-cores"
  let coresDest = Root & "/dist/RetroArch/.retroarch"
  if dirExists(coresStaging):
    echo "Staging RetroArch cores from: ", coresStaging
    mkDir(coresDest)
    for kind, path in walkDir(coresStaging):
      let dest = coresDest & "/" & path.splitPath.tail
      if kind == pcDir:
        cpDir(path, dest)
      else:
        cpFile(path, dest)
  else:
    echo "Warning: no RetroArch cores found at ", coresStaging, " - skipping"

  selfExec "e scripts/updateLocales.nims " & ver & " dist/trimui/res/lang"

  exec "nimble buildBins"

  exec "nimble thirdparty"
  for tpb in thirdPartyBins:
    mvFile(&"{Root}/{tpb}", &"dist/System/bin/{tpb.split('/')[^1]}")

  cd("dist")
  exec &"zip -9r {Root}/{zipName} * -x '*.gitkeep'"

task updater, "Prepare updater package":
  let ver = getBuildVer()
  let baseZip = getZipName("BASE", ver)
  let updateZip =
    if isNightly(): &"Quark_Update_{ver}.zip"
    else: &"Quark_Update_v{ver}.zip"
  let updaterZip = getZipName("Updater", ver)

  if not fileExists(baseZip):
    exec "nimble base"

  cpFile(baseZip, updateZip)
  exec &"zip --delete {updateZip} 'Updater/*'"

  stageAndZip("dist_updater_temp", updaterZip, proc() =
    mkDir("dist_updater_temp/Apps")
    cpDir("dist/Apps/QuarkUpdater", "dist_updater_temp/Apps/QuarkUpdater")
    cpDir("dist/Updater", "dist_updater_temp/Updater")
    mvFile(updateZip, &"dist_updater_temp/{updateZip}")
  )

task full, "Prepare base, full and updater zips for release":
  let ver = getBuildVer()
  let baseZip = getZipName("BASE", ver)
  let fullZip = getZipName("FULL", ver)

  if not fileExists(baseZip):
    exec "nimble updater"

  echo "Creating full zip from base zip..."
  cpFile(baseZip, fullZip)

  echo "Copying gluons into zip..."
  for category in @["Systems", "Themes"]:
    let categoryPath = Root & "/modules/gluons/" & category
    if dirExists(categoryPath):
      for d in listDirs(categoryPath):
        let gluonPath = &"{categoryPath}/{d}/mnt/SDCARD"
        if dirExists(gluonPath):
          cd(gluonPath)
          exec &"zip -9ur {Root}/{fullZip} * -x '*.gitkeep'"

  cd(Root)
  echo "Full zip created: ", fullZip
