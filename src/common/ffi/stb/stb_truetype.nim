import std/os

const StbDir = currentSourcePath().splitPath().head /
  ".." / ".." / ".." / ".." /
  "modules" / "third-party" / "stb"

{.passC: "-O3 -I" & StbDir.}

{.emit: """
#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"
""".}

type
  stbtt_fontinfo* {.importc, header: StbDir / "stb_truetype.h".} = object

proc stbtt_InitFont*(info: ptr stbtt_fontinfo, data: ptr UncheckedArray[byte], offset: cint): cint
  {.importc, header: StbDir / "stb_truetype.h".}

proc stbtt_ScaleForPixelHeight*(info: ptr stbtt_fontinfo, pixels: cfloat): cfloat
  {.importc, header: StbDir / "stb_truetype.h".}

proc stbtt_GetFontVMetrics*(info: ptr stbtt_fontinfo, ascent, descent, lineGap: ptr cint)
  {.importc, header: StbDir / "stb_truetype.h".}

proc stbtt_GetCodepointBitmapBox*(info: ptr stbtt_fontinfo, codepoint: cint,
  scale_x, scale_y: cfloat, ix0, iy0, ix1, iy1: ptr cint)
  {.importc, header: StbDir / "stb_truetype.h".}

proc stbtt_MakeCodepointBitmap*(info: ptr stbtt_fontinfo, output: ptr UncheckedArray[byte],
  out_w, out_h, out_stride: cint, scale_x, scale_y: cfloat, codepoint: cint)
  {.importc, header: StbDir / "stb_truetype.h".}

proc stbtt_GetCodepointHMetrics*(info: ptr stbtt_fontinfo, codepoint: cint,
  advanceWidth, leftSideBearing: ptr cint)
  {.importc, header: StbDir / "stb_truetype.h".}

proc stbtt_GetCodepointKernAdvance*(info: ptr stbtt_fontinfo, ch1, ch2: cint): cint
  {.importc, header: StbDir / "stb_truetype.h".}
