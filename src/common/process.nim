import std/[os, posix, strformat, strutils, sets]

proc killall*(processName: string, signal: cint): bool =
  var killed = false
  
  for kind, path in walkDir("/proc"):
    if kind == pcDir:
      let name = path.extractFilename()
      try:
        let pid = parseInt(name)
        
        let commPath = path / "comm"
        if fileExists(commPath):
          let comm = readFile(commPath).strip()
          
          if comm == processName:
            if kill(cint(pid), signal) == 0:
              killed = true
      except ValueError:
        continue
  
  result = killed

proc getProcessChildren*(ppid: int, pids: var HashSet[int]) =
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
