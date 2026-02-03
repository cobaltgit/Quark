import std/[os, strutils, json, random, sets, posix, times]

const
  EmuDir = "/mnt/SDCARD/Emus"
  RomsBase = "/mnt/SDCARD/Roms"

func normalizeExt(ext: string): string {.inline.} =
  if ext.len <= 1: return ""
  ext[1 .. ^1].toLowerAscii()

func jsonStr(node: JsonNode, key: string): string {.inline.} =
  if node.hasKey(key) and node[key].kind == JString:
    node[key].getStr()
  else:
    ""

proc listDir(path: string): seq[string] =
  result = @[]

  for kind, p in walkDir(path, relative = false):
    if kind == pcFile or kind == pcDir:
      let (_, name, _) = splitFile(p)
      if name.len > 0 and name[0] != '.':
        result.add(p)

proc buildExtSet(extlist: string): HashSet[string] =
  result = initHashSet[string]()
  for e in extlist.split('|'):
    let n = e.toLowerAscii()
    if n.len > 0:
      result.incl(n)

func hasExtension(path: string, extset: HashSet[string]): bool {.inline.} =
  normalizeExt(splitFile(path).ext) in extset

proc getRoms(systemPath: string): seq[string] =
  let cfg = parseFile(systemPath / "config.json")
  
  var romPath = jsonStr(cfg, "rompath")

  if romPath.len == 0:
    romPath = RomsBase / splitPath(systemPath).tail
  elif romPath[0] != '/':
    romPath = systemPath / romPath

  let all = listDir(romPath)

  let extlist = jsonStr(cfg, "extlist")
  if extlist.len == 0:
    return all

  let extset = buildExtSet(extlist)

  result = @[]

  for f in all:
    if hasExtension(f, extset):
      result.add(f)


proc main() =
  randomize(getTime().toUnix)

  let argv = commandLineParams()
  let shouldLaunch = "--launch" in argv

  var systemArg = ""
  for a in argv:
    if a != "--launch":
      systemArg = a
      break

  let systems = listDir(EmuDir)
  if systems.len == 0:
    stderr.writeLine("No systems found")
    quit(1)

  var chosenSystem =
    if systemArg.len > 0:
      EmuDir / systemArg
    else:
      systems[rand(systems.high)]

  if not dirExists(chosenSystem) or
     systemArg.startsWith("/") or
     systemArg.contains(".."):
    stderr.writeLine(chosenSystem & ": invalid or nonexistent directory")
    quit(1)

  while true:
    try:
      let roms = getRoms(chosenSystem)
      if roms.len > 0:
        let chosenRom = roms[rand(roms.high)]
        echo chosenRom
        
        if shouldLaunch:
          let cfg = parseFile(chosenSystem / "config.json")
          var launchPath = jsonStr(cfg, "launch")
          if launchPath.len == 0:
            let sysName = splitPath(chosenSystem).tail
            launchPath = EmuDir / sysName / "launch.sh"
          elif launchPath[0] != '/':
            launchPath = chosenSystem / launchPath

          var args = allocCStringArray(@["/bin/sh", launchPath, chosenRom])
          discard execv("/bin/sh", args)
        break
      raise newException(IOError, "No ROMs")

    except:
      if systemArg.len == 0:
        chosenSystem = systems[rand(systems.high)]
      else:
        stderr.writeLine("No ROMs in system '" &
                         splitPath(chosenSystem).tail & "'")
        quit(1)

when isMainModule:
  main()

