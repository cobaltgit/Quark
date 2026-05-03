import std/[os, osproc, posix, sets, strformat, strutils, times]
import ../common/[fb, led, process, reboot]

proc screenshotHandler*(fbMap: pointer) =
  setLedTrigger(LedColour.Green, LedTrigger.On)
  let now = now()
  let filename = &"/mnt/SDCARD/Saves/screenshots/Screenshot_{now.year:04}{ord(now.month):02}{now.monthday:02}_{now.hour:02}{now.minute:02}{now.second:02}.png"

  try:
    fbscreenshot(fbMap, filename)
  except:
    discard

  setLedTrigger(LedColour.Green, LedTrigger.Off)

proc quicksaveHandler*() =
  discard startProcess("/bin/sh", args = @["/mnt/SDCARD/System/scripts/quicksave.sh"])

proc killHandler*() =
  var cmdPid = -1

  for kind, path in walkDir("/proc"):
    if kind == pcDir:
      let name = path.extractFilename()
      if name.len > 0 and name[0].isDigit:
        try:
          let cmdlinePath = path / "cmdline"
          if fileExists(cmdlinePath):
            let cmdline = readFile(cmdlinePath)
            if "/tmp/cmd_to_run.sh" in cmdline:
              cmdPid = parseInt(name)
              break
        except:
          discard

  if cmdPid > 0:
    var tree = initHashSet[int]()
    tree.incl(cmdPid)
    getProcessChildren(cmdPid, tree)

    for pid in tree:
      discard kill(Pid(pid), SIGTERM)

proc rebootHandler*() =
  killHandler()
  sleep(500)
  sync()
  fbclear()
  discard reboot(RB_AUTOBOOT)
