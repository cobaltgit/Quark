import std/[os, osproc, posix, sets, strformat, strutils, times]
import ../common/[fbscreenshot, led, reboot]

proc getProcessChildren(ppid: int, pids: var HashSet[int]) =
  for kind, path in walkDir("/proc"):
    if kind == pcDir:
      let name = path.extractFilename()
      if name.len > 0 and name[0].isDigit:
        try:
          let pid = parseInt(name)
          let statPath = &"/proc/{pid}/stat"
          if fileExists(statPath):
            let stat = readFile(statPath)
            var fields = 0
            var parentPid = 0
            var inParen = false
            var field = ""
            
            for c in stat:
              if c == '(':
                inParen = true
              elif c == ')':
                inParen = false
              elif c == ' ' and not inParen:
                inc fields
                if fields == 4:
                  try:
                    parentPid = parseInt(field)
                  except ValueError:
                    discard
                  break
                field = ""
              else:
                if not inParen or fields > 0:
                  field.add(c)
            
            if parentPid == ppid:
              pids.incl(pid)
              getProcessChildren(pid, pids)
        except:
          discard

proc screenshotHandler*() =
  setLedTrigger(LedColour.Green, LedTrigger.On)
  let now = now()
  let filename = &"/mnt/SDCARD/Saves/screenshots/Screenshot_{now.year:04}{ord(now.month):02}{now.monthday:02}_{now.hour:02}{now.minute:02}{now.second:02}.png"
  
  try:
    fbscreenshot(filename)
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
  discard reboot(RB_AUTOBOOT)
