import json

type
  Settings* = object
    audioLatency*: float

var settings*: Settings

proc initSettings*() =
  settings = parseFile("data/settings.json").to(Settings)
