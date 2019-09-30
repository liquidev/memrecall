import os
import parseopt
import tables

import rapid/res/textures
import rapid/gfx/fxsurface
import rapid/gfx/text
import rapid/gfx

import effects

const
  Tc* = RTextureConfig (minFilter: fltNearest, magFilter: fltNearest,
                        wrapH: wrapClampToBorder, wrapV: wrapClampToBorder)

var
  args*: Table[string, string]

  win*: RWindow
  surface*: RGfx
  mainCanvas*: RCanvas
  canvasScale*, winScale*: float
  canvasPos*, canvasSize*: Vec2[float]

  mansalva*: RFont

  fx*, cfx*: RFxSurface
  fxHDisplace*: REffect
  fxRgbSplit*: REffect

proc initRes*() =
  for kind, k, v in getopt(commandLineParams()):
    args.add(k, v)

  win = initRWindow()
    .size(768, 576)
    .title("_MEM.RECALL();")
    .open()
  surface = win.openGfx()
  mainCanvas = newRCanvas(128, 96, Tc)

  mansalva = loadRFont("data/fonts/Mansalva/Mansalva-Regular.ttf", 32, 0,
                       Tc, 4096, 4096)

  fx = newRFxSurface(surface.canvas, Tc)
  cfx = newRFxSurface(mainCanvas, Tc)
  fxHDisplace = fx.newREffect(HDisplacement)
  fxRgbSplit = fx.newREffect(RgbSplit)
