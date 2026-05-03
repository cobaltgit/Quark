import std/[cmdline, posix, strformat]
from common/fb import fbscreenshot, FbSize

when isMainModule:
  if paramCount() < 1:
    stderr.writeLine "usage: fbscreenshot <output>"
    quit(1)

  let output = paramStr(1)

  try:
    let fbFd = open("/dev/fb0", O_RDONLY)
    if fbFd < 0:
      raise newException(IOError, "failed to open framebuffer")

    let fbMap = mmap(nil, FbSize, PROT_READ, MAP_SHARED, fbFd, 0)
    if fbMap == MAP_FAILED:
      raise newException(IOError, "failed to map framebuffer")

    try:
      fbscreenshot(fbMap, output)
      echo &"fbscreenshot: Saved screenshot to '{output}'"
    finally:
      discard close(fbFd)
      discard munmap(fbMap, FbSize)
  except Exception as e:
    stderr.writeLine &"fbscreenshot: Failed saving screenshot to '{output}': {e.msg}"
    quit(1)
