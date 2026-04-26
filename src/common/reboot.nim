import std/posix

const
  SYS_reboot = cast[clong](88)

  LINUX_REBOOT_MAGIC1 = cast[clong](0xfee1dead'u32)
  LINUX_REBOOT_MAGIC2 = cast[clong](0x28121969'u32)

  RB_AUTOBOOT* = cast[clong](0x01234567'u32)
  RB_HALT_SYSTEM* = cast[clong](0xCDEF0123'u32)
  RB_POWER_OFF* = cast[clong](0x4321FEDC'u32)
  RB_ENABLE_CAD* = cast[clong](0x89ABCDEF'u32)
  RB_DISABLE_CAD* = cast[clong](0x00000000'u32)

proc syscall(number: clong, arg1: clong, arg2: clong, arg3: clong, arg4: clong): clong
  {.importc, header: "<unistd.h>", varargs.}

proc reboot*(cmd: clong): clong =
  syscall(SYS_reboot, LINUX_REBOOT_MAGIC1, LINUX_REBOOT_MAGIC2, cmd, 0)
