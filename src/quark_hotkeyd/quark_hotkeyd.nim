import std/[posix, strformat, strutils, times, os, sets, options, monotimes]
from std/monotimes import MonoTime

from ../common import fbscreenshot
from evdev import InputEvent, EventKind, KeyCode

const 
  InputDev = "/dev/input/event0"

type
  KeyBitSet = object
    bits: array[12, uint64]

  TriggerKind = enum
    tkPress
    tkHold

  Trigger = object
    case kind: TriggerKind
    of tkPress:
      discard
    of tkHold:
      duration: Duration

  HotkeyState = object
    wasDown: bool
    armedAt: Option[MonoTime]
    fired: bool

  HotkeyEvent = object
    keys: seq[KeyCode]
    trigger: Trigger
    callback: proc() {.closure.}
    state: HotkeyState

proc newKeyBitSet(): KeyBitSet =
  result.bits = default(array[12, uint64])

proc set(self: var KeyBitSet, code: KeyCode, down: bool) {.inline.} =
  let idx = uint16(code.ord) shr 6
  let mask = 1'u64 shl (uint16(code.ord) and 63)
  
  if idx >= uint16(self.bits.len):
    return
  
  if down:
    self.bits[idx] = self.bits[idx] or mask
  else:
    self.bits[idx] = self.bits[idx] and (not mask)

proc get(self: KeyBitSet, code: KeyCode): bool {.inline.} =
  let idx = uint16(code.ord) shr 6
  let bit = uint16(code.ord) and 63
  
  if idx >= uint16(self.bits.len):
    return false
  
  result = ((self.bits[idx] shr bit) and 1) == 1

proc newPressHotkey(keys: seq[KeyCode], callback: proc()): HotkeyEvent =
  result.keys = keys
  result.trigger = Trigger(kind: tkPress)
  result.callback = callback
  result.state = HotkeyState()

proc newHoldHotkey(keys: seq[KeyCode], duration: Duration, callback: proc()): HotkeyEvent =
  result.keys = keys
  result.trigger = Trigger(kind: tkHold, duration: duration)
  result.callback = callback
  result.state = HotkeyState()

proc shouldFire(self: var HotkeyEvent, chordDown: bool): bool =
  case self.trigger.kind
  of tkPress:
    let fire = chordDown and not self.state.wasDown
    self.state.wasDown = chordDown
    return fire
    
  of tkHold:
    if chordDown:
      if self.state.fired:
        return false
      
      if self.state.armedAt.isNone:
        self.state.armedAt = some(getMonoTime())
        return false
      else:
        let elapsed = getMonoTime() - self.state.armedAt.get()
        if elapsed >= self.trigger.duration:
          self.state.fired = true
          return true
        else:
          return false
    else:
      self.state.armedAt = none(MonoTime)
      self.state.fired = false
      return false

proc setLed(led: int, on: bool) =
  let ledPath = &"/sys/devices/platform/sunxi-led/leds/led{led}/trigger"
  let ledStatus = if on: "default-on" else: "none"
  
  try:
    writeFile(ledPath, ledStatus)
  except IOError:
    discard

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
                if fields == 3:
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

proc killCmdToRun() =
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

proc screenshotHandler() =
  setLed(2, true)
  let now = now()
  let filename = &"/mnt/SDCARD/Saves/screenshots/Screenshot_{now.year:04}{ord(now.month):02}{now.monthday:02}_{now.hour:02}{now.minute:02}{now.second:02}.png"
  
  try:
    fbscreenshot(filename)
  except:
    discard
  
  setLed(2, false)

proc quicksaveHandler() =
  discard execl("/bin/sh", "sh", "/mnt/SDCARD/System/scripts/quicksave.sh", nil)

proc killHandler() =
  killCmdToRun()

proc rebootHandler() =
  killCmdToRun()
  sleep(500)
  sync()
  discard execl("/mnt/SDCARD/System/bin/reboot", "reboot", nil)

proc pollReadable(fd: cint, timeoutMs: cint): bool =
  var pfd = TPollfd(fd: fd, events: POLLIN, revents: 0)
  let rc = poll(addr pfd, 1, timeoutMs)
  result = rc > 0 and (pfd.revents and POLLIN) != 0

proc main() =
  let fd = posix.open(InputDev, O_RDONLY or O_NONBLOCK)
  if fd < 0:
    stderr.writeLine "Failed to open input device"
    quit(1)
  
  defer: discard close(fd)
  
  var pressedKeys = newKeyBitSet()
  
  var hotkeys = @[
    newPressHotkey(@[KeyCode.KEY_RIGHTCTRL, KeyCode.KEY_PAGEDOWN], screenshotHandler),
    newPressHotkey(@[KeyCode.KEY_RIGHTCTRL, KeyCode.KEY_PAGEUP], quicksaveHandler),
    newPressHotkey(@[KeyCode.KEY_ENTER, KeyCode.KEY_PAGEUP], killHandler),
    newHoldHotkey(@[KeyCode.KEY_RIGHTCTRL, KeyCode.KEY_ENTER], initDuration(seconds = 10), rebootHandler),
  ]
  
  while true:
    if pollReadable(fd, 250):
      var event: InputEvent
      while true:
        let bytesRead = read(fd, addr event, sizeof(InputEvent))
        if bytesRead != sizeof(InputEvent):
          break
        
        if event.kind == EventKind.EV_KEY.ord:
          case event.value
          of 1:
            pressedKeys.set(event.code, true)
          of 0:
            pressedKeys.set(event.code, false)
          else:
            discard
    
    for hk in hotkeys.mitems:
      var chordDown = true
      for key in hk.keys:
        if not pressedKeys.get(key):
          chordDown = false
          break
      
      if hk.shouldFire(chordDown):
        hk.callback()

when isMainModule:
  main()
