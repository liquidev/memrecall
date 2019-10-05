import json

type
  Settings* = object
    audioLatency*: float
    music*: bool

var settings*: Settings

proc initSettings*() =
  settings = parseFile("data/settings.json").to(Settings)
