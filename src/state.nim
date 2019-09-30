import random
import strutils

import rapid/math/interpolation
import rapid/gfx/fxsurface
import rapid/gfx/text
import rapid/gfx

import res

type
  State* = enum
    stateTitle
    stateGame
    stateEnd

var
  gameState* = stateGame

var
  titleWords = @["NO", "TITLE"]
  titleTime = -100.0

proc setTitle*(text: string) =
  titleWords = text.splitWhitespace
  titleTime = time()

proc drawTitle*(ctx: RGfxContext) =
  let
    currentTime = time() - titleTime
    totalTime = titleWords.len.float / 3
  if currentTime < totalTime:
    let
      wordn = int currentTime * 3
      word = titleWords[wordn]
      wordTime = (currentTime - wordn / 3) * 3
    mansalva.height = int 96 * winScale
    fx.begin(ctx)
    ctx.transform:
      let scale = 1 - (hermite(wordTime / 2 + 0.5) * 0.4)
      ctx.translate(canvasSize.x / 2, canvasSize.y / 2)
      ctx.scale(scale, scale)
      ctx.text(mansalva, 0, 0, word,
               hAlign = taCenter, vAlign = taMiddle)
    fxHDisplace.param("time", time())
    fx.effect(fxHDisplace)
    fx.finish()

var
  hint = "No hint"
  hintPos = taTop
  hintTime = -100.0
  hintOpacity = 0.0

proc setHint*(text: string, pos: RTextVAlign) =
  hint = text
  hintPos = pos
  hintTime = time()

proc drawHint*(ctx: RGfxContext, step: float) =
  let currentTime = time() - hintTime
  if currentTime in 0.0..4.0 and hintOpacity < 1: hintOpacity += 0.02 * step
  elif currentTime in 4.0..5.0 and hintOpacity > 0: hintOpacity -= 0.02 * step
  hintOpacity = hintOpacity.clamp(0, 1)
  if hintOpacity > 0:
    ctx.color = gray(255, int(hintOpacity * 255))
    mansalva.height = int 32 * winScale
    ctx.text(mansalva, 0, 48, hint, canvasSize.x, canvasSize.y - 96,
             hAlign = taCenter, vAlign = hintPos)

var
  flashEnd: float
  shakeStart = -100.0
  shakeTime = 1.0
  shakeIntensity: float

proc flashScreen*(time: float) =
  flashEnd = time() + time

proc drawFlash*(ctx: RGfxContext) =
  if time() < flashEnd:
    ctx.begin()
    ctx.color = gray(255)
    ctx.rect(0, 0, surface.width, surface.height)
    ctx.draw()

proc shakeScreen*(time, intensity: float) =
  shakeStart = time()
  shakeTime = time
  shakeIntensity = intensity

proc shakeOffset*(): Vec2[float] =
  if time() - shakeStart < shakeTime:
    let amp = (shakeTime - (time() - shakeStart)) / shakeTime * shakeIntensity
    if amp > 0:
      result = vec2(rand(-amp..amp), rand(-amp..amp))
