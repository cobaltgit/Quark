import std/[cmdline, os, posix]
import ../common/[bootlogo, reboot]
import ../display/display

when isMainModule:
  var shouldReboot = false
  var input = "bootlogo.bmp"

  for i in 1..paramCount():
    let param = paramStr(i)
    if param == "--reboot":
      shouldReboot = true
    else:
      input = param

  try:
    writeBootlogo(input)
    echo "Bootlogo written successfully!"
    if shouldReboot:
      sync()
      discard reboot(RB_AUTOBOOT)
  except Exception as e:
    display(e.msg, duration = 1500)
    quit(1)
