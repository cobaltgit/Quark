import std/[os, posix, strformat, strutils, sets, tables]

proc getParentPid(pid: int): int =
  try:
    let stat = readFile(&"/proc/{pid}/stat")
    let afterComm = stat.find(')')
    if afterComm < 0:
      return -1
    let fields = stat[afterComm + 2 .. ^1].splitWhitespace()
    if fields.len >= 2:
      result = parseInt(fields[1])
    else:
      result = -1
  except CatchableError:
    result = -1

proc getProcessMap(): Table[string, seq[int]] =
  result = initTable[string, seq[int]]()
  for kind, path in walkDir("/proc"):
    if kind != pcDir:
      continue
    let name = path.extractFilename()
    try:
      let pid = parseInt(name)
      let commPath = path / "comm"
      if fileExists(commPath):
        let comm = readFile(commPath).strip()
        if comm notin result:
          result[comm] = @[]
        result[comm].add(pid)
    except CatchableError:
      continue

proc killall*(processName: string, signal: cint, excludePid: int = -1): bool =
  let processMap = getProcessMap()
  if processName notin processMap:
    return false

  for pid in processMap[processName]:
    if pid == excludePid:
      continue
    if kill(cint(pid), signal) == 0:
      result = true

proc getProcessChildren*(ppid: int, pids: var HashSet[int]) =
  for kind, path in walkDir("/proc"):
    if kind != pcDir:
      continue
    let name = path.extractFilename()
    if name.len == 0 or not name[0].isDigit:
      continue
    try:
      let pid = parseInt(name)
      if getParentPid(pid) == ppid:
        pids.incl(pid)
        getProcessChildren(pid, pids)
    except CatchableError:
      continue
