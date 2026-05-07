import std/os

const StbDir = currentSourcePath().splitPath().head /
  ".." / ".." / ".." / ".." /
  "modules" / "third-party" / "stb"

{.passC: "-O3 -I" & StbDir.}

{.emit: """
#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image.h"
#include "stb_image_write.h"
""".}

proc stbi_load*(
  filename: cstring,
  x: ptr cint,
  y: ptr cint,
  channels_in_file: ptr cint,
  desired_channels: cint
): ptr uint8 {.importc, header: StbDir / "stb_image.h".}

proc stbi_write_png*(
  filename: cstring,
  w: cint,
  h: cint,
  comp: cint,
  data: pointer,
  stride_in_bytes: cint
): cint {.importc, header: StbDir / "stb_image_write.h".}

proc stbi_image_free*(data: pointer) {.importc, header: StbDir / "stb_image.h".}
