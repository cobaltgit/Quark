switch("cpu", "arm")
switch("os", "linux")

switch("define", "release")
switch("define", "strip")
switch("opt", "size")

# run nimble install zigcc
switch("cc", "clang")
switch("clang.exe", "zigcc")
switch("clang.linkerexe", "zigcc")

switch("passC", "-target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7 -Os")
switch("passL", "-target arm-linux-gnueabihf.2.23 -mcpu=cortex_a7 -Os")
