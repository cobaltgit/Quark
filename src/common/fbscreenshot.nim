import nimPNG

const 
  FbWidth = 240
  FbHeight = 320
  FbPixels = FbWidth * FbHeight

proc fbscreenshot*(output: string) =
  let fbFile = open("/dev/fb0", fmRead)
  defer: fbFile.close()
  
  var fbData: array[FbPixels * 2, uint8]
  let bytesRead = fbFile.readBuffer(addr fbData[0], fbData.len)
  
  if bytesRead != fbData.len:
    raise newException(IOError, "Failed to read complete framebuffer data")
  
  var rotatedPixels = newSeq[uint8](FbHeight * FbWidth * 4)

  for y in 0..<FbHeight:
    for x in 0..<FbWidth:
      let idx = (y * FbWidth * 2 + x * 2)
      let pixel = uint16(fbData[idx]) or (uint16(fbData[idx + 1]) shl 8)

      let r = uint8((pixel shr 11) and 0x1F)
      let g = uint8((pixel shr 5) and 0x3F)
      let b = uint8(pixel and 0x1F)

      let dstX = FbHeight - 1 - y
      let dstY = x
      let dstIdx = (x * FbHeight + dstX) * 4

      rotatedPixels[dstIdx] = (r shl 3) or (r shr 2)
      rotatedPixels[dstIdx + 1] = (g shl 2) or (g shr 4)
      rotatedPixels[dstIdx + 2] = (b shl 3) or (b shr 2)
      rotatedPixels[dstIdx + 3] = 255
  
  discard savePNG32(output, rotatedPixels, FbHeight, FbWidth)
