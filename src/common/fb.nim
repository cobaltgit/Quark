import std/posix
import ffi/stb/stb_image

const
  FbWidth* = 240
  FbHeight* = 320
  FbPixels* = FbWidth * FbHeight
  FbSize* = FbPixels * sizeof(uint16)

  # Compile-time lookup tables!
  FiveToEight*: array[32, uint8] = block:
    var arr: array[32, uint8]
    for i in 0..31:
      arr[i] = uint8((i shl 3) or (i shr 2))
    arr

  SixToEight*: array[64, uint8] = block:
    var arr: array[64, uint8]
    for i in 0..63:
      arr[i] = uint8((i shl 2) or (i shr 4))
    arr

  FbXBase*: array[FbHeight, uint32] = block:
    var arr: array[FbHeight, uint32]
    for x in 0..<FbHeight:
      arr[x] = uint32((FbHeight - 1 - x) * FbWidth)
    arr

{.push optimization:speed, checks:off, warnings:off.}

proc fbclear*() =
  let fd = posix.open("/dev/fb0", O_RDWR)
  if fd < 0:
    raise newException(IOError, "Unable to open framebuffer")

  defer: discard close(fd)

  let fbMap = mmap(nil, FbSize, PROT_READ or PROT_WRITE, MAP_SHARED, fd, 0)

  if fbMap == MAP_FAILED:
    raise newException(IOError, "Unable to map framebuffer")

  defer: discard munmap(fbMap, FbSize)

  zeroMem(fbMap, FbSize)

proc fbscreenshot*(fbMap: pointer, output: string) =
  let fbData = cast[ptr UncheckedArray[uint16]](fbMap)
  var rotatedPixels = newSeqUninit[uint32](FbPixels)

  for x in 0..<FbWidth:
    let colBase = x * FbHeight
    var srcBase = x * 2

    for y in 0..<FbHeight:
      let pixel = fbData[srcBase]
      srcBase += FbWidth * 2

      rotatedPixels[colBase + FbHeight - 1 - y] = uint32(FiveToEight[(pixel shr 11) and 0x1F]) or
        (uint32(SixToEight[(pixel shr 5) and 0x3F]) shl 8) or
        (uint32(FiveToEight[pixel and 0x1F]) shl 16) or
        0xFF000000'u32

  discard stbi_write_png(
    cstring(output),
    cint(FbHeight),
    cint(FbWidth),
    cint(4),
    addr rotatedPixels[0],
    cint(FbHeight * 4)
  )
