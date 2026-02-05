import std/[os, json, strutils, parseopt]

# Get version from command line
var appVersion = "unknown"
var langDir = "dist/trimui/res/lang"

var p = initOptParser()
while true:
  p.next()
  case p.kind
  of cmdEnd: break
  of cmdArgument:
    if appVersion == "unknown":
      appVersion = p.key
    else:
      langDir = p.key
  else: discard

proc updateLangFile(path: string) =
  let content = parseJson(readFile(path))
  var updated = content
  
  if updated.hasKey("30"):
    let originalText = updated["30"].getStr()
    
    let quarkPos = originalText.find("QUARK")
    if quarkPos >= 0:
      let prefix = originalText[0 ..< quarkPos + 5]
      updated["30"] = %(prefix & " " & appVersion)
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
