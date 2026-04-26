import std/[os, json, strutils]

let allParams = commandLineParams()

var startIdx = 0
for i, p in allParams:
  if p.endsWith(".nims"):
    startIdx = i + 1
    break

let appVersion = if startIdx < allParams.len: allParams[startIdx] else: "unknown"
let langDir = if startIdx + 1 < allParams.len: allParams[startIdx + 1] else: "dist/trimui/res/lang"

proc updateLangFile(path: string) =
  let content = parseJson(readFile(path))
  var updated = content

  if updated.hasKey("30"):
    let originalText = updated["30"].getStr()
    let quarkPos = originalText.find("QUARK")
    if quarkPos >= 0:
      updated["30"] = %(originalText[0 ..< quarkPos + 5] & " " & appVersion)
    else:
      echo "  Warning: 'QUARK' not found in ", path
      updated["30"] = %(originalText & " - QUARK " & appVersion)
  else:
    updated["30"] = %("Device Info - QUARK " & appVersion)

  writeFile(path, pretty(updated, indent=1) & "\n")

echo "Updating localisation files in: ", langDir
echo "Version: ", appVersion

var filesUpdated = 0
for file in listFiles(langDir):
  if file.endsWith(".lang"):
    echo "  ", file
    updateLangFile(file)
    inc filesUpdated

echo "Updated ", filesUpdated, " language file(s)"
