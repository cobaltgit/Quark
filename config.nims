switch("cpu", "arm")
switch("os", "linux")

switch("threads", "off")
switch("define", "release")
switch("define", "strip")
switch("opt", "size")
switch("mm", "arc")

# run nimble install zigcc!
switch("cc", "clang")
switch("clang.exe", "zigcc")
switch("clang.linkerexe", "zigcc")

switch("passC",
  "-target arm-linux-gnueabihf.2.23 " &
  "-mcpu=cortex_a7 " &
  "-ffunction-sections -fdata-sections -fno-unwind-tables -fno-asynchronous-unwind-tables"
)

switch("passL",
  "-target arm-linux-gnueabihf.2.23 " &
  "-Wl,--gc-sections -Wl,--strip-all"
)
