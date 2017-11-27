# Package

version       = "0.1.0"
author        = "skilchen"
description   = "a almost complete translation of julias Base.Dates to Nim"
license       = "MIT"

bin           = @["jlDates"]

skipDirs      = @["experiments"]

# Dependencies
requires "nim >= 0.17.3"

task tests, "Run the jlDates tests":
  exec "nim c -r jlDatespkg/tests/alltests"

