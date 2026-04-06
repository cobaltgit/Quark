import std/[os, posix, strutils]
import nimPNG

import ../common/[fb, process]
import stb_truetype

const
  ScreenWidth = 320
  ScreenHeight = 240

  DefaultBackground* = "/mnt/SDCARD/System/res/quarkbg.png"
  DefaultFont* = "/mnt/SDCARD/System/res/TwCenMT.ttf"
  FontSize = 24.0

var childPid: Pid = -1

proc toRGB565(r, g, b: uint8): uint16 {.inline.} =
  (uint16(EightToFive[r]) shl 11) or
  (uint16(EightToSix[g]) shl 5) or
  uint16(EightToFive[b])

proc fromRGB565(pixel: uint16, r, g, b: var uint8) {.inline.} =
  r = FiveToEight[(pixel shr 11) and 0x1F]
  g = SixToEight[(pixel shr 5) and 0x3F]
  b = FiveToEight[pixel and 0x1F]

proc setPixel(fb: ptr UncheckedArray[uint16], x, y: int, color: uint16) {.inline.} =
  if x >= 0 and x < SCREEN_WIDTH and y >= 0 and y < SCREEN_HEIGHT:
    let fbIdx = RowOffsets[RotationXMap[x]] + y
    fb[fbIdx] = color

proc getPixel(fb: ptr UncheckedArray[uint16], x, y: int): uint16 {.inline.} =
  if x >= 0 and x < SCREEN_WIDTH and y >= 0 and y < SCREEN_HEIGHT:
    let fbIdx = RowOffsets[RotationXMap[x]] + y
    return fb[fbIdx]
  return 0

proc loadFont(path: string): seq[byte] =
  let f = open(path, fmRead)
  defer: f.close()
  let size = f.getFileSize()
  result = newSeqUninit[byte](size)
  discard f.readBytes(result, 0, size)

proc measureText(font: ptr stbtt_fontinfo, text: string, scale: cfloat): int =
  var x: cint = 0
  for i, ch in text:
    var advanceWidth, leftSideBearing: cint
    stbtt_GetCodepointHMetrics(font, cint(ch), addr advanceWidth, addr leftSideBearing)
    x += advanceWidth
    if i < text.len - 1:
      let kern = stbtt_GetCodepointKernAdvance(font, cint(ch), cint(text[i+1]))
      x += kern
  result = int(cfloat(x) * scale)

proc wrapText(text: string, font: ptr stbtt_fontinfo, scale: cfloat, maxWidth: int): seq[string] =
  result = @[]
  var currentLine = ""
  var currentWidth = 0

  for word in text.split(' '):
    let wordWidth = measureText(font, word & " ", scale)

    if currentWidth + wordWidth > maxWidth and currentLine.len > 0:
      result.add(currentLine.strip())
      currentLine = word & " "
      currentWidth = wordWidth
    else:
      currentLine &= word & " "
      currentWidth += wordWidth

  if currentLine.len > 0:
    result.add(currentLine.strip())

proc renderTextLine(fb: ptr UncheckedArray[uint16], font: ptr stbtt_fontinfo,
                    text: string, y: int, pixelHeight: float, color: uint16) =
  let scale = stbtt_ScaleForPixelHeight(font, cfloat(pixelHeight))

  var ascent, descent, lineGap: cint
  stbtt_GetFontVMetrics(font, addr ascent, addr descent, addr lineGap)

  let textWidth = measureText(font, text, scale)
  var x = (ScreenWidth - textWidth) div 2
  let baseline = y + int(cfloat(ascent) * scale)

  var cr, cg, cb: uint8
  fromRGB565(color, cr, cg, cb)

  for i, ch in text:
    var ix0, iy0, ix1, iy1: cint
    stbtt_GetCodepointBitmapBox(font, cint(ch), scale, scale,
                                addr ix0, addr iy0, addr ix1, addr iy1)

    let w = ix1 - ix0
    let h = iy1 - iy0

    if w > 0 and h > 0:
      var bitmap = newSeq[byte](w * h)
      stbtt_MakeCodepointBitmap(font, cast[ptr UncheckedArray[byte]](addr bitmap[0]),
                                w, h, w, scale, scale, cint(ch))

      for by in 0..<h:
        for bx in 0..<w:
          let alpha = bitmap[by * w + bx]
          if alpha > 0:
            let px = x + int(ix0) + bx
            let py = baseline + int(iy0) + by

            if px >= 0 and px < ScreenWidth and py >= 0 and py < ScreenHeight:
              let bgPixel = getPixel(fb, px, py)

              var bgR, bgG, bgB: uint8
              fromRGB565(bgPixel, bgR, bgG, bgB)

              let a = cfloat(alpha) / 255.0
              let newR = uint8(cfloat(cr) * a + cfloat(bgR) * (1.0 - a))
              let newG = uint8(cfloat(cg) * a + cfloat(bgG) * (1.0 - a))
              let newB = uint8(cfloat(cb) * a + cfloat(bgB) * (1.0 - a))

              setPixel(fb, px, py, toRGB565(newR, newG, newB))

    var advanceWidth, leftSideBearing: cint
    stbtt_GetCodepointHMetrics(font, cint(ch), addr advanceWidth, addr leftSideBearing)
    x += int(cfloat(advanceWidth) * scale)

    if i < text.len - 1:
      let kern = stbtt_GetCodepointKernAdvance(font, cint(ch), cint(text[i+1]))
      x += int(cfloat(kern) * scale)

proc display*(text: string,
              backgroundPath: string = DefaultBackground,
              fontPath: string = DefaultFont,
              duration: int = 0,
              persistent: bool = false) =

  if childPid > 0:
    var status: cint
    discard kill(childPid, SIGKILL)
    discard waitpid(childPid, status, 0)
    childPid = -1

  let fbFd = posix.open("/dev/fb0", O_RDWR)
  if fbFd < 0:
    raise newException(IOError, "display: failed to open /dev/fb0")
  defer: discard close(fbFd)

  let fbMap = mmap(nil, FbSize, PROT_READ or PROT_WRITE, MAP_SHARED, fbFd, 0)
  if fbMap == MAP_FAILED:
    raise newException(IOError, "display: failed to mmap framebuffer")
  defer: discard munmap(fbMap, FbSize)

  let fb = cast[ptr UncheckedArray[uint16]](fbMap)

  if not fileExists(backgroundPath):
    raise newException(IOError, "display: background file not found: " & backgroundPath)

  let png = loadPNG32(backgroundPath)

  var srcIdx = 0
  for ly in 0..<min(png.height, ScreenHeight):
    for lx in 0..<min(png.width, ScreenWidth):
      let r = png.data[srcIdx]
      let g = png.data[srcIdx + 1]
      let b = png.data[srcIdx + 2]
      srcIdx += 4
      fb[RowOffsets[RotationXMap[lx]] + ly] = toRGB565(r.uint8, g.uint8, b.uint8)

  if png.width < ScreenWidth or png.height < ScreenHeight:
    for ly in 0..<ScreenHeight:
      for lx in 0..<ScreenWidth:
        if lx >= png.width or ly >= png.height:
          setPixel(fb, lx, ly, 0)

  if not fileExists(fontPath):
    raise newException(IOError, "display: font file not found: " & fontPath)

  let fontData = loadFont(fontPath)
  var fontInfo: stbtt_fontinfo
  if stbtt_InitFont(addr fontInfo,
      cast[ptr UncheckedArray[byte]](unsafeAddr fontData[0]), 0) == 0:
    raise newException(IOError, "display: failed to load font: " & fontPath)

  let scale = stbtt_ScaleForPixelHeight(addr fontInfo, cfloat(FontSize))
  let lines = wrapText(text, addr fontInfo, scale, ScreenWidth - 40)

  let lineHeight = int(FontSize * 1.2)
  var startY = (ScreenHeight - lines.len * lineHeight) div 2

  for line in lines:
    renderTextLine(fb, addr fontInfo, line, startY, FontSize,
                    toRGB565(255, 255, 255))
    startY += lineHeight

  if duration == 0:
    if not persistent:
      let pid = fork()
      if pid < 0:
        raise newException(OSError, "display: failed to fork")
      elif pid > 0:
        childPid = pid
        return
      discard setsid()
      discard close(0)
      discard close(1)
      discard close(2)
    while true:
      discard pause()
  else:
    sleep(duration)

proc showUsage(progName: string) =
  stderr.writeLine("Usage: " & progName & " -t \"text\" [-b background.png] [-d duration_ms] [-f font.ttf]")
  stderr.writeLine("  -t  Text to display (required)")
  stderr.writeLine("  -b  Background PNG image (default: quarkbg.png)")
  stderr.writeLine("  -d  Display duration in milliseconds (default: 0 = forever)")
  stderr.writeLine("  -f  Font file path (default: TwCenMT.ttf)")
  stderr.writeLine("  -p  Don't fork into the background (only applies if duration is 0)")

proc main() =
  var
    backgroundPath = DefaultBackground
    fontPath       = DefaultFont
    duration       = 0
    text           = ""
    hasText        = false
    persistent     = false

  discard killall("display", SIGKILL, getpid())

  var i = 1
  while i <= paramCount():
    let param = paramStr(i)
    if param.startsWith("-"):
      let option = param[1..^1]
      case option
      of "t":
        if i + 1 <= paramCount():
          text = paramStr(i + 1)
          hasText = true
          inc i
        else:
          stderr.writeLine("display: -t requires a text argument")
          showUsage(getAppFilename())
          quit(1)
      of "b":
        if i + 1 <= paramCount():
          backgroundPath = paramStr(i + 1)
          inc i
        else:
          stderr.writeLine("display: -b requires a path argument")
          showUsage(getAppFilename())
          quit(1)
      of "d":
        if i + 1 <= paramCount():
          let durationStr = paramStr(i + 1).strip()
          if durationStr.len > 0:
            try:
              duration = parseInt(durationStr)
            except ValueError:
              stderr.writeLine("display: invalid duration value: '" & durationStr & "'"); quit(1)
          inc i
        else:
          stderr.writeLine("display: -d requires a duration argument")
          showUsage(getAppFilename())
          quit(1)
      of "f":
        if i + 1 <= paramCount():
          fontPath = paramStr(i + 1)
          inc i
        else:
          stderr.writeLine("display: -f requires a font path argument")
          showUsage(getAppFilename())
          quit(1)
      of "p":
        persistent = true
      else:
        stderr.writeLine("display: unknown option -" & option)
        showUsage(getAppFilename())
        quit(1)
    else:
      if not hasText:
        text = param
        hasText = true
    inc i

  if not hasText or text.len == 0:
    stderr.writeLine("display: no text provided")
    showUsage(getAppFilename())
    quit(1)

  try:
    display(text, backgroundPath, fontPath, duration, persistent)
  except Exception as e:
    stderr.writeLine(e.msg)
    quit(1)

when isMainModule:
  main()
