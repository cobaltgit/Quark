import std/[cmdline, os, posix]
import ../common/[bootlogo, reboot]

when isMainModule:
  let input = if paramCount() < 1:
    "bootlogo.bmp"
  else:
    paramStr(1)
  
  try:
    writeBootlogo(input)
    echo "Bootlogo written successfully!"
    if "--reboot" in commandLineParams():
      sync()
      discard reboot(RB_AUTOBOOT)
  except Exception as e:
    stderr.writeLine(e.msg)
    quit(1)

