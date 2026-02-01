version       = "1.7.0"
author        = "cobaltgit"
description   = "Quark utilities for TrimUI Smart"
license       = "MIT"
srcDir        = "src"
binDir        = "build"
bin           = @["fbscreenshot/fbscreenshot", "quark_hotkeyd/quark_hotkeyd", "sysjson_monitor/sysjson_monitor"]


requires "nim >= 2.0.0"
requires "nimPNG >= 0.3.1"

