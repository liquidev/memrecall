#--
# Package
#--

version = "2.0.0"
author = "lqdev"
description =
  "Explore an abandoned time travel lab and uncover its deepest secrets. " &
  "A metroidvania-like platformer, originally made for Open Jam 2019."
license = "GPL-3.0"
srcDir = "src"
bin = @["memrecall"]

#--
# Dependencies
#--

requires "nim >= 1.0.0"
requires "rapid#head"
requires "yaml#head"
