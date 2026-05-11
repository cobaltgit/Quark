import std/[posix, times, options, monotimes]

import ../common/evdev
import handlers

from ../common/fb import FbSize

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

  if idx < uint16(self.bits.len):
    self.bits[idx] = (self.bits[idx] and not mask) or (uint64(down) and mask)

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

proc main() =
  let fbFd = open("/dev/fb0", O_RDONLY)
  if fbFd < 0:
    stderr.writeLine "failed to open framebuffer"
    quit(1)

  let fbMap = mmap(nil, FbSize, PROT_READ, MAP_SHARED, fbFd, 0)
  if fbMap == MAP_FAILED:
    discard close(fbFd)
    stderr.writeLine "failed to mmap framebuffer"
    quit(1)

  defer:
    discard munmap(fbMap, FbSize)
    discard close(fbFd)

  let evFd = posix.open(InputDev, O_RDONLY or O_NONBLOCK)
  if evFd < 0:
    stderr.writeLine "failed to open " & InputDev
    quit(1)

  defer: discard close(evFd)

  var pressedKeys = newKeyBitSet()

  var hotkeys = @[
    newPressHotkey(@[KeyCode.KEY_RIGHTCTRL, KeyCode.KEY_PAGEDOWN], proc() = screenshotHandler(fbMap)),
    newPressHotkey(@[KeyCode.KEY_RIGHTCTRL, KeyCode.KEY_PAGEUP], quicksaveHandler),
    newPressHotkey(@[KeyCode.KEY_ENTER, KeyCode.KEY_PAGEUP], killHandler),
    newHoldHotkey(@[KeyCode.KEY_RIGHTCTRL, KeyCode.KEY_ENTER], initDuration(seconds = 10), rebootHandler),
  ]

  while true:
    if pollReadable(evFd, 250):
      var event: InputEvent
      while true:
        let bytesRead = read(evFd, addr event, sizeof(InputEvent))
        if bytesRead != sizeof(InputEvent):
          break

        if event.kind == EventKind.EV_KEY.ord:
          pressedKeys.set(event.code, event.value == 1)

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
