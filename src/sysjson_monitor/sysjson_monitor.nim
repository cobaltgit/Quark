import std/[os, strutils, tables, posix, osproc, inotify, options]
import ../common/[bootlogo, reboot]

const
  MaxBufSize = 8192

type
  SystemConfig = object
    values: Table[string, string]
    
proc parseSystemJson(input: string): SystemConfig =
  result.values = initTable[string, string]()

  for line in input.splitLines():
    let colonPos = line.find(':')
    if colonPos > 0:
      let keyPart = line[0..<colonPos]
        .strip()
        .strip(chars = {'"', '\t', ' '})

      let valuePart = line[colonPos+1..^1]
        .strip()
        .strip(trailing = true, chars = {',', '}', '"'})
        .strip(leading = true, chars = {'"'})
        .strip()

      if keyPart.len > 0 and valuePart.len > 0:
        var isAlphaNum = true
        for c in keyPart:
          if not c.isAlphaNumeric:
            isAlphaNum = false
            break

        if isAlphaNum:
          result.values[keyPart] = valuePart

proc getString(config: SystemConfig, key: string): Option[string] =
  if key in config.values:
    some(config.values[key])
  else:
    none(string)

proc getInt(config: SystemConfig, key: string): Option[int] =
  if key in config.values:
    try:
      some(parseInt(config.values[key]))
    except ValueError:
      none(int)
  else:
    none(int)

proc getSystemJson(): SystemConfig =
  parseSystemJson(readFile("/mnt/UDISK/system.json"))

proc getVolume(config: SystemConfig): Option[int] =
  config.getInt("vol")

proc getThemePath(config: SystemConfig): Option[string] =
  let pathOpt = config.getString("theme")
  if pathOpt.isSome:
    var p = pathOpt.get()
    if not p.endsWith('/'):
      p.add('/')
    some(p)
  else:
    none(string)

proc isCharacterDevice(path: string): bool =
  var st: Stat
  stat(path, st) == 0 and S_ISCHR(st.st_mode)

proc setVolume(volume: int64) =
  if not isCharacterDevice("/dev/audio1"):
    return

  let volPercent = volume * 5
  discard execCmd("amixer -c 1 sset PCM " & $volPercent & "%")

proc main() =
  let json = getSystemJson()
  var themePath = getThemePath(json).get("")
  var volume = getVolume(json).get(0)

  let inotifyFd = inotify_init()
  if inotifyFd < 0:
    quit("Failed to init inotify")

  let sysJsonWd = inotify_add_watch(inotifyFd, "/mnt/UDISK/system.json", IN_MODIFY)
  if sysJsonWd < 0:
    quit("Failed to add watch for system.json")

  let devWd = inotify_add_watch(inotifyFd, "/dev", IN_CREATE)
  if devWd < 0:
    quit("Failed to add watch for /dev")

  var buffer: array[MaxBufSize, byte]

  while true:
    let n = read(inotifyFd, buffer.addr, MaxBufSize)
    if n <= 0:
      continue

    for ePtr in inotify_events(buffer.addr, n):
      let e = ePtr

      let name =
        if e.len > 0:
          $cast[cstring](addr e.name)
        else:
          ""

      if e.wd == sysJsonWd and (e.mask and IN_MODIFY.uint32) != 0:
        try:
          let json2 = getSystemJson()

          let newThemePath = getThemePath(json2)
          if newThemePath.isSome and newThemePath.get() != themePath:
            themePath = newThemePath.get()
            let bootlogoPath = themePath & "skin/bootlogo.bmp"

            if fileExists(bootlogoPath):
              try:
                writeBootlogo(bootlogoPath)
              except:
                discard

            sync()
            discard reboot(RB_AUTOBOOT)

          let newVolume = getVolume(json2)
          if newVolume.isSome and newVolume.get() != volume:
            volume = newVolume.get()
            setVolume(volume)
        except:
          stderr.writeLine("Error reading JSON")

      elif e.wd == devWd and (e.mask and IN_CREATE.uint32) != 0:
        if name == "audio1":
          if isCharacterDevice("/dev/audio1"):
            sleep(100)
            try:
              let json3 = getSystemJson()
              let vol = getVolume(json3)
              if vol.isSome:
                setVolume(vol.get())
            except:
              stderr.writeLine("Error setting volume on device creation")


when isMainModule:
  main()

