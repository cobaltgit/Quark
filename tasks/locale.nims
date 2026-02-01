task updateLocales, "Update version in localisation files":
  when defined(nightly):
    let gitHash = gorge("git rev-parse --short=8 HEAD")
    echo "Updating locales with nightly version: ", gitHash
    exec "nim e scripts/updateLocales.nims " & gitHash & " static/trimui/res/lang"
  else:
    echo "Updating locales with stable version: v", version
    exec "nim e scripts/updateLocales.nims " & version & " static/trimui/res/lang"
