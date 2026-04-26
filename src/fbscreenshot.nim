import std/[cmdline, strformat]
from common/fb import fbscreenshot

when isMainModule:
  if paramCount() < 1:
    stderr.writeLine "usage: fbscreenshot <output>"
    quit(1)

  let output = paramStr(1)

  try:
    fbscreenshot(output)
    echo &"fbscreenshot: Saved screenshot to '{output}'"
  except Exception as e:
    stderr.writeLine &"fbscreenshot: Failed saving screenshot to '{output}': {e.msg}"
    quit(1)
