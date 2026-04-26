import std/posix
import nimPNG

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

proc fbscreenshot*(output: string) =
  let fbFile = system.open("/dev/fb0", fmRead)
  defer: fbFile.close()

  var fbData: array[FbSize, uint8]
  let bytesRead = fbFile.readBuffer(addr fbData[0], fbData.len)

  if bytesRead != fbData.len:
    raise newException(IOError, "Failed to read complete framebuffer data")

  var rotatedPixels = newSeqUninit[uint8](FbPixels * 4)

  for x in 0..<FbWidth:
    let colBase = x * FbHeight
    var srcBase = x * 2

    for y in 0..<FbHeight:
      let pixel = uint16(fbData[srcBase]) or (uint16(fbData[srcBase + 1]) shl 8)
      srcBase += FbWidth * 2

      let r = (pixel shr 11) and 0x1F
      let g = (pixel shr 5) and 0x3F
      let b = pixel and 0x1F

      let dstIdx = (colBase + FbHeight - 1 - y) * 4
      rotatedPixels[dstIdx] = FiveToEight[r]
      rotatedPixels[dstIdx + 1] = SixToEight[g]
      rotatedPixels[dstIdx + 2] = FiveToEight[b]
      rotatedPixels[dstIdx + 3] = 255

  discard savePNG32(output, rotatedPixels, FbHeight, FbWidth)
