task updateLocales, "Update version in localisation files":
  let ver = getBuildVer()
  if isNightly(): echo "Updating locales with nightly version: ", ver
  else: echo "Updating locales with stable version: v", ver
  exec "nim e scripts/updateLocales.nims " & ver & " static/trimui/res/lang"
