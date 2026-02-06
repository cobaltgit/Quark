import std/[cmdline, strformat]
import ../common/bootlogo

when isMainModule:
  let input = if paramCount() < 1:
    "bootlogo.bmp"
  else:
    paramStr(1)
  
  try:
    writeBootlogo(input)
    echo &"Bootlogo written successfully!"
  except Exception as e:
    stderr.writeLine(e.msg)
    quit(1)

