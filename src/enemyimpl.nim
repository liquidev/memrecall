import rapid/world/sprite
import rapid/world/tilemap
import rapid/gfx

import enemydef
import level
import particlesys
import random

proc vertexCount(sprite: EnemySprite): int =
  case sprite
  of esCircle: 13
  of esTriangle: 4
  of esSquare: 5

method draw*(enemy: Enemy, ctx: RGfxContext, step: float) =
  case enemy.sprite
  of esCircle, esTriangle, esSquare:
    ctx.transform:
      ctx.translate(enemy.pos.x, enemy.pos.y)
      ctx.translate(4, 4)
      ctx.rotate(time() * enemy.sprite.vertexCount.float)
      ctx.clearStencil(255)
      ctx.stencil(saReplace, 0):
        ctx.begin()
        ctx.circle(0, 0, 2, enemy.sprite.vertexCount)
        ctx.draw()
      ctx.stencilTest = (scEq, 255)
      ctx.begin()
      ctx.circle(0, 0, 4, enemy.sprite.vertexCount)
      ctx.draw()
      ctx.noStencilTest()
  if enemy.particles mod 2 == 0:
    particles.emit(pos = enemy.pos + 4,
                   vel = vec2(rand(-1.0..1.0), rand(-1.0..1.0)),
                   decel = 0.2, life = rand(0.2..0.5))
  inc(enemy.particles)

method update*(enemy: Enemy, step: float) =
  proc collision(dx, dy: float, tiles: set[Tile]): bool =
    let
      tx = int (enemy.pos.x + dx) / 8
      ty = int (enemy.pos.y + dy) / 8
    result = world[tx, ty] in tiles

  const Solid = {tileSolid, tileEnemyBarrier}

  case enemy.movement
  of emLinearUp, emLinearDown:
    if collision(4, -1, Solid):
      enemy.vel = vec2(0.0, 1.0)
    elif collision(4, 8, Solid):
      enemy.vel = vec2(0.0, -1.0)
  of emLinearLeft, emLinearRight:
    if collision(-1, 4, Solid):
      enemy.vel = vec2(1.0, 0.0)
    elif collision(8, 4, Solid):
      enemy.vel = vec2(-1.0, 0.0)
