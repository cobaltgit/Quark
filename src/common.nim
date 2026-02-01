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
  
  var pixels = newSeq[uint8](FbWidth * FbHeight * 4)
  
  for y in 0..<FbHeight:
    for x in 0..<FbWidth:
      let idx = (y * FbWidth * 2 + x * 2)
      let pixel = uint16(fbData[idx]) or (uint16(fbData[idx + 1]) shl 8)
      
      let r = uint8((pixel shr 11) and 0x1F)
      let g = uint8((pixel shr 5) and 0x3F)
      let b = uint8(pixel and 0x1F)
      
      let pixelIdx = (y * FbWidth + x) * 4
      pixels[pixelIdx + 0] = (r shl 3) or (r shr 2)
      pixels[pixelIdx + 1] = (g shl 2) or (g shr 4)
      pixels[pixelIdx + 2] = (b shl 3) or (b shr 2)
      pixels[pixelIdx + 3] = 255
  
  var rotated = newSeq[uint8](FbHeight * FbWidth * 4)
  for y in 0..<FbHeight:
    for x in 0..<FbWidth:
      let srcIdx = (y * FbWidth + x) * 4
      let dstX = FbHeight - 1 - y
      let dstY = x
      let dstIdx = (dstY * FbHeight + dstX) * 4
      
      rotated[dstIdx + 0] = pixels[srcIdx + 0]
      rotated[dstIdx + 1] = pixels[srcIdx + 1]
      rotated[dstIdx + 2] = pixels[srcIdx + 2]
      rotated[dstIdx + 3] = pixels[srcIdx + 3]
  
  discard savePNG32(output, rotated, FbHeight, FbWidth)
