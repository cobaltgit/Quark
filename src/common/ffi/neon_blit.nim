{.compile: "neon_blit.c".}
{.passC: "-mfpu=neon-vfpv4 -mfloat-abi=hard -O3".}

proc rgba_to_rgb565*(src: ptr UncheckedArray[uint8],
                    dst: ptr UncheckedArray[uint16],
                    n: cint) {.importc, noconv.}

proc blit_transposed*(src: ptr UncheckedArray[uint16],
                     dst: ptr UncheckedArray[uint16],
                     width, height: cint) {.importc, noconv.}
