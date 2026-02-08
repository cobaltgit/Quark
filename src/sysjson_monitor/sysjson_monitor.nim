import std/[os, posix, osproc, inotify, options]
import ../common/[bootlogo, reboot]
import config

const
  MaxBufSize = 8192

proc isCharacterDevice(path: string): bool =
  var st: Stat
  stat(path, st) == 0 and S_ISCHR(st.st_mode)

proc setVolume(volume: int64) =
  if not isCharacterDevice("/dev/audio1"):
    return

  let volPercent = volume * 5
  discard execCmd("amixer -c 1 sset PCM " & $volPercent & "%")

proc main() =
  var json = getConfig()
  var themePath = json.getString("theme").get("")
  var volume = json.getInt("vol").get(0)

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
          
      json = getConfig()

      if e.wd == sysJsonWd and (e.mask and IN_MODIFY.uint32) != 0:
        try:
          let newThemePath = json.getString("theme")
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

          let newVolume = json.getInt("vol")
          if newVolume.isSome and newVolume.get() != volume:
            volume = newVolume.get()
            setVolume(volume)
        except:
          stderr.writeLine("Error reading JSON")

      elif e.wd == devWd and (e.mask and IN_CREATE.uint32) != 0 and 
        name == "audio1" and isCharacterDevice("/dev/audio1"):
          sleep(100)
          try:
            let vol = json.getInt("vol")
            if vol.isSome:
              setVolume(vol.get())
          except:
            stderr.writeLine("Error setting volume on device creation")


when isMainModule:
  main()

