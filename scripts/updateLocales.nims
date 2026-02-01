import std/[os, json, strutils, parseopt]

# Get version from command line
var appVersion = "unknown"
var langDir = "static/trimui/res/lang"

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
  # Use readFile + parseJson instead of parseFile (which uses C FFI)
  let content = parseJson(readFile(path))
  var updated = content
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
