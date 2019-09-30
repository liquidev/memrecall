import math

import rapid/gfx

proc qline*(ctx: RGfxContext, x0, y0, x1, y1, width: float) =
  ctx.transform:
    let
      dx = x1 - x0
      dy = y1 - y0
    ctx.translate(x0, y0)
    ctx.rotate(arctan2(dy, dx))
    ctx.rect(0, -width / 2, sqrt(dx * dx + dy * dy), width)

proc qrect*(ctx: RGfxContext, x, y, w, h: float) =
  ctx.rect(x, y, w, 1)
  ctx.rect(x, y + 1, 1, h - 2)
  ctx.rect(x, y + h - 1, w, 1)
  ctx.rect(x + w - 1, y + 1, 1, h - 2)
