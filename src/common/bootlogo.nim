import std/[os, streams]

const
  REQUIRED_WIDTH = 240
  REQUIRED_HEIGHT = 320
  MAX_BOOTLOGO_SIZE = 524288  # size of /dev/mmcblk0p2
  HEADER_SIZE = 54

proc validateBmp(path: string) =
  if not fileExists(path):
    raise newException(IOError, path & ": no such file")
  
  let fileSize = getFileSize(path)
  if fileSize > MAX_BOOTLOGO_SIZE:
    raise newException(ValueError, path & ": must be under 512KiB!")
  
  var fs = newFileStream(path, fmRead)
  if fs.isNil:
    raise newException(IOError, path & ": failed to open file")
  
  defer: fs.close()
  
  var header: array[HEADER_SIZE, uint8]
  if fs.readData(addr header[0], HEADER_SIZE) != HEADER_SIZE:
    raise newException(IOError, path & ": failed to open file")
  
  if header[0] != 'B'.uint8 or header[1] != 'M'.uint8:
    raise newException(ValueError, path & ": not a valid BMP image")
  
  let width = cast[ptr int32](addr header[18])[]
  let height = cast[ptr int32](addr header[22])[]
  let bitsPerPixel = cast[ptr uint16](addr header[28])[]
  let compression = cast[ptr uint32](addr header[30])[]
  
  if bitsPerPixel != 16 or compression != 3:
    raise newException(ValueError, path & ": must be RGB565 format")
  
  if width != REQUIRED_WIDTH or abs(height) != REQUIRED_HEIGHT:
    raise newException(ValueError, path & ": must be 240x320 resolution")

proc writeBootlogo*(path: string) =
  var bmpFile = newFileStream(path, fmRead)
  if bmpFile.isNil:
    raise newException(IOError, path & ": failed to open file")

  defer: bmpFile.close()
  
  var bootlogoDev = newFileStream("/dev/by-name/bootlogo", fmWrite)
  if bootlogoDev.isNil:
    raise newException(IOError, "Failed to open /dev/by-name/bootlogo")
    
  defer: bootlogoDev.close()
  
  const CHUNK_SIZE = 4096
  var buf: array[CHUNK_SIZE, uint8]
  var bytesRead = bmpFile.readData(addr buf[0], CHUNK_SIZE)
  
  while bytesRead > 0:
    bootlogoDev.writeData(addr buf[0], bytesRead)
    bytesRead = bmpFile.readData(addr buf[0], CHUNK_SIZE)
  
  bootlogoDev.flush()
