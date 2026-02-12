import std/posix
import nimPNG

const 
  FbWidth = 240
  FbHeight = 320
  FbPixels = FbWidth * FbHeight
  FbSize = FbPixels * sizeof(uint16)

  # RGB565 -> RGB888 lookup tables computed at compile time
  FiveToEight: array[32, uint8] = block:
    var arr: array[32, uint8]
    for i in 0..31:
      arr[i] = uint8((i shl 3) or (i shr 2))
    arr

  SixToEight: array[64, uint8] = block:
    var arr: array[64, uint8]
    for i in 0..63:
      arr[i] = uint8((i shl 2) or (i shr 4))
    arr

proc fbclear*() =
  let fd = open("/dev/fb0", O_RDWR)
  if fd < 0:
    raise newException(IOError, "Unable to open framebuffer")

  defer: discard fd.close()
  
  let fbMap = mmap(nil, FbSize, PROT_READ or PROT_WRITE, MAP_SHARED, fd, 0)

  if fbMap == MAP_FAILED:
    raise newException(IOError, "Unable to map framebuffer")

  defer: discard munmap(fbMap, FbSize)

  zeroMem(fbMap, FbSize)

proc fbscreenshot*(output: string) =
  let fbFile = open("/dev/fb0", fmRead)
  defer: fbFile.close()
  
  var fbData: array[FbSize, uint8]
  let bytesRead = fbFile.readBuffer(addr fbData[0], fbData.len)
  
  if bytesRead != fbData.len:
    raise newException(IOError, "Failed to read complete framebuffer data")
  
  var rotatedPixels = newSeqUninit[uint8](FbSize * 2)

  var srcIdx = 0
  for y in 0..<FbHeight:
    for x in 0..<FbWidth:
      let pixel = uint16(fbData[srcIdx]) or (uint16(fbData[srcIdx + 1]) shl 8)
      srcIdx += 2

      let r = (pixel shr 11) and 0x1F
      let g = (pixel shr 5) and 0x3F
      let b = pixel and 0x1F

      let dstIdx = (x * FbHeight + (FbHeight - 1 - y)) * 4

      rotatedPixels[dstIdx] = FiveToEight[r]
      rotatedPixels[dstIdx + 1] = SixToEight[g]
      rotatedPixels[dstIdx + 2] = FiveToEight[b]
      rotatedPixels[dstIdx + 3] = 255
  
  discard savePNG32(output, rotatedPixels, FbHeight, FbWidth)

