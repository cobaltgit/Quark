import std/os

{.compile("stb_image.c", "-O3").}
{.compile("stb_image_write.c", "-O3").}
{.passC: "-I" & currentSourcePath().splitPath().head.}

proc stbi_load*(
  filename: cstring,
  x: ptr cint,
  y: ptr cint,
  channels_in_file: ptr cint,
  desired_channels: cint
): ptr uint8 {.importc, header: "stb_image.h".}

proc stbi_write_png*(
  filename: cstring,
  w: cint,
  h: cint,
  comp: cint,
  data: pointer,
  stride_in_bytes: cint
): cint {.importc, header: "stb_image_write.h".}

proc stbi_image_free*(data: pointer) {.importc, header: "stb_image.h".}
