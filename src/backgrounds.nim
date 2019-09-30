import random

import rapid/gfx

import drawutils

type
  Background* = enum
    bgNone = "none"
    bgLines = "lines"
    bgLab = "lab"
    bgSine = "sine"
  Line = object
    x, y: float
    dir: float
  Rect = object
    x, y: float
    vertical: bool

var
  frame = 0
  lines: seq[Line]
  rects: seq[Rect]

proc drawBackground*(bg: Background, col: RColor,
                     ctx: RGfxContext, step: float) =
  case bg
  of bgNone: discard
  of bgLines:
    var garbage: seq[int]
    ctx.begin()
    ctx.color = rgba(col.ired, col.igreen, col.iblue, 16)
    var i = 0
    for ln in lines.mitems:
      if ln.dir < 0:
        ctx.rect(ln.x, ln.y, 24, 1)
        ctx.rect(ln.x, ln.y, 12, 1)
        ctx.rect(ln.x, ln.y, 6, 1)
      else:
        ctx.rect(ln.x, ln.y, 24, 1)
        ctx.rect(ln.x + 12, ln.y, 12, 1)
        ctx.rect(ln.x + 18, ln.y, 6, 1)
      ln.x += ln.dir * step / 2
      if ln.x < -24 or ln.x > 152:
        garbage.add(i)
      inc(i)
    ctx.draw()
    for i in countdown(garbage.len - 1, 0):
      lines.delete(i)
    if frame mod 5 == 0:
      if rand(0..1) == 0:
        lines.add(Line(x: -24, y: rand(0..<96).float, dir: 2))
      else:
        lines.add(Line(x: 152, y: rand(0..<96).float, dir: -2))
  of bgLab:
    var garbage: seq[int]
    ctx.begin()
    ctx.color = rgba(col.ired, col.igreen, col.iblue, 16)
    var i = 0
    for r in rects.mitems:
      if r.vertical:
        ctx.qrect(r.x, r.y.round, 12, 24)
        r.y += step * 1.5
      else:
        ctx.qrect(r.x.round, r.y, 24, 12)
        r.x += step * 1.5
      if r.x > 152 or r.y > 120:
        garbage.add(i)
      inc(i)
    ctx.draw()
    for i in countdown(garbage.len - 1, 0):
      rects.delete(i)
    if frame mod 10 == 0:
      if rand(0..1) == 0:
        rects.add(Rect(x: -24, y: rand(0..<96).float, vertical: false))
      else:
        rects.add(Rect(x: rand(0..<128).float, y: -24, vertical: true))
  of bgSine:
    ctx.begin()
    ctx.color = rgba(col.ired, col.igreen, col.iblue, 16)
    for j in 0..<2:
      for i in 0..<64:
        let
          x = i.float * 2 + j.float
          h = sin(time() * 2 + i / 17 + j.float) * 32
        ctx.rect(x, 48, 1, h)
        ctx.rect(x, 48, 1, h / 2)
        ctx.rect(x, 48, 1, h / 3)
    ctx.draw()
  inc(frame)
