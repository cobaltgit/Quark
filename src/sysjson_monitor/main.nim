import std/[os, posix, inotify, options]
import ../common/[bootlogo, process, reboot]
import ../common/ffi/amixer
import config

from ../common/fb import fbclear

const
  MaxBufSize = 8192

proc isCharacterDevice(path: string): bool =
  var st: Stat
  stat(path, st) == 0 and S_ISCHR(st.st_mode)

proc setVolume(volume: int64) =
  if not isCharacterDevice("/dev/audio1"):
    return

  let volPercent = volume * 5

  var mixer: SndMixerT
  if snd_mixer_open(addr mixer, 0) < 0:
    return
  defer: discard snd_mixer_close(mixer)

  if snd_mixer_attach(mixer, "hw:1") < 0: return
  if snd_mixer_selem_register(mixer, nil, nil) < 0: return
  if snd_mixer_load(mixer) < 0: return

  let idSize = snd_mixer_selem_id_sizeof()
  var idBuf  = alloc0(idSize)
  defer: dealloc(idBuf)
  let sid    = cast[SndMixerSelemIdT](idBuf)

  snd_mixer_selem_id_set_index(sid, 0)
  snd_mixer_selem_id_set_name(sid, "PCM")

  let elem = snd_mixer_find_selem(mixer, sid)
  if elem == nil:
    return

  var minVol, maxVol: clong
  discard snd_mixer_selem_get_playback_volume_range(elem, addr minVol, addr maxVol)

  let rawVol = minVol + clong((maxVol - minVol) * volPercent div 100)
  discard snd_mixer_selem_set_playback_volume_all(elem, rawVol)

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

            discard killall("MainUI", SIGKILL)
            fbclear()
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
