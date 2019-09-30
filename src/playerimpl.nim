import math
import random

import rapid/world/sprite
import rapid/world/tilemap
import rapid/gfx/fxsurface
import rapid/gfx/text
import rapid/gfx

import enemydef
import level
import particlesys
import playerdef
import powerups
import res
import sounds
import state
import xmath

proc canDash(player: Player): bool = player.hasDash and not player.dashUsed

method draw*(player: Player, ctx: RGfxContext, step: float) =
  if not player.dead:
    if player.canDash:
      ctx.transform:
        ctx.translate(player.dashDot.x, player.dashDot.y)
        cfx.begin(ctx)
        ctx.begin()
        ctx.circle(0, 0, 2, 6)
        ctx.draw()
        fxRgbSplit.param("offset", vec2f(sin(time() * (PI / 2)) + 1, 0))
        cfx.effect(fxRgbSplit)
        cfx.finish()
    ctx.clearStencil(255)
    ctx.stencil(saReplace, 0):
      ctx.begin()
      ctx.rect(player.pos.x + 2, player.pos.y + 2, 4, 4)
      ctx.draw()
    ctx.stencilTest = (scEq, 255)
    ctx.begin()
    ctx.rect(player.pos.x, player.pos.y, 8, 8)
    ctx.draw()
    ctx.noStencilTest()

proc flippedMul(player: Player): float =
  result = -float(ord(player.flipped) * 2 - 1)

proc dash(player: Player) =
  player.dashUsed = true
  player.dashEnd = time() + 0.15
  shakeScreen(0.1, 5)
  for i in 0..<8:
    let angle = PI / 4 * i.float
    particles.emit(pos = player.dashDot,
                   vel = vec2(cos(angle), sin(angle)) * 2,
                   decel = 0.8, life = 0.1)

proc refillDash(player: Player) =
  if player.dashUsed:
    player.dashUsed = false
    for i in 0..<8:
      let angle = PI / 4 * i.float
      particles.emit(pos = player.dashDot,
                     vel = vec2(cos(angle), sin(angle)) * 2,
                     decel = 0.8, life = 0.1)

proc controls(player: Player, step: float) =
  for ev in player.controlBuffer.mitems:
    if not ev.expired:
      case ev.control
      of ctrlJump:
        if player.vel.y == 0:
          player.jumpTime = 8
          ev.used = true
      of ctrlFlip:
        if player.canFlip and player.vel.y == 0:
          player.flipped = not player.flipped
          player.vel.y = 2 * player.flippedMul
          ev.used = true
      of ctrlDash:
        if player.canDash:
          player.dash()
        ev.used = true

  if player.hasDash:
    player.speed = 0.5
  elif player.canFlip:
    player.speed = 0.6

  if win.key(keyLeft) == kaDown:
    player.dashDir = pdLeft
    player.force(vec2(-player.speed, 0))
  if win.key(keyRight) == kaDown:
    player.dashDir = pdRight
    player.force(vec2(player.speed, 0))

  const
    Jump = 2.5
  if win.key(keyUp) == kaDown and player.jumpTime > 0:
    player.vel.y = -Jump * player.flippedMul
    player.jumpTime -= step
  elif win.key(keyUp) == kaUp:
    player.jumpTime = 0

  if time() < player.dashEnd:
    player.vel = vec2(player.dashDir.float * 5, 0)
    particles.emit(pos = player.pos + vec2(rand(0.0..8.0), rand(0.0..8.0)),
                    vel = vec2(-player.dashDir.float * rand(1.0..2.0),
                              rand(-0.1..0.1)),
                    decel = 0.95, life = rand(0.2..0.5))

proc kill*(player: Player) =
  if not player.dead:
    flashScreen(0.02)
    shakeScreen(0.1, 10)
    playSound(sndDeath)
    player.dead = true
    player.deathTime = time()
    for i in 1..100:
      let
        angle = rand(0.0..2 * PI)
        speed = rand(1.0..4.0)
      particles.emit(pos = player.pos + 4,
                     vel = vec2(cos(angle) * speed, sin(angle) * speed),
                     decel = 0.9, life = rand(0.2..0.7))
    inc(player.deaths)

method update*(player: Player, step: float) =
  const
    Dec = 0.7
    Gravity = vec2(0.0, 0.15)

  if not player.dead:
    if player.dashUsed and time() > player.dashEnd + 0.2 and
       player.pvel.y == 0.0 and player.vel.y == 0.0:
      player.refillDash()

    player.controls(step)
    if time() > player.dashEnd:
      player.force(Gravity * player.flippedMul)
    player.vel.x *= Dec
    player.vel.y = player.vel.y.clamp(-2.5, 2.5)

    proc collides(dx, dy: float, tiles: set[Tile]): bool =
      let
        tx = int (player.pos.x + dx) / 8
        ty = int (player.pos.y + dy) / 8
      result = world[tx, ty] in tiles

    const
      Kill = {tileSpikes}
      Flip = {tileFlipPlaneH, tileFlipPlaneV}
    if collides(7, 4, Kill) or collides(4, 7, Kill) or
       collides(1, 4, Kill) or collides(4, 1, Kill):
      player.kill()

    proc flipCollides(): bool = collides(4, 4, Flip)
    if not player.hitFlipPlane and flipCollides():
      playSound(sndPlane)
      player.flipped = not player.flipped
      player.hitFlipPlane = true
      player.vel.y *= -0.5
      player.refillDash()
    if player.hitFlipPlane and not flipCollides():
      player.hitFlipPlane = false
  else:
    player.vel = vec2(0.0)
    player.flipped = false

  if player.dead and time() - player.deathTime > 1.0:
    player.dead = false
    player.pos = player.respawnPoint

  block updateDashDot:
    let
      target = player.pos + 4 + vec2(-player.dashDir.float, 0.0) * 8
      dist = dist(target, player.dashDot)
      angle = arctan2(target.y - player.dashDot.y,
                      target.x - player.dashDot.x)
    player.dashDot += vec2(cos(angle), sin(angle)) * dist * 0.2

  player.pvel = player.vel

method collideSprite*(player: Player, sprite: RSprite) =
  if sprite of Checkpoint:
    let checkpoint = sprite.Checkpoint
    if not checkpoint.collected:
      for s in world.sprites:
        if s of Checkpoint:
          s.Checkpoint.collected = false
      checkpoint.collect()
      player.respawnPoint = sprite.pos
  elif sprite of Atom:
    sprite.Atom.collect()
    inc(player.atoms)
  elif sprite of FlipPack:
    sprite.FlipPack.collect()
    player.canFlip = true
    setHint("Press X to flip gravity", taBottom)
  elif sprite of DashPack:
    sprite.DashPack.collect()
    player.hasDash = true
    setHint("Press Z to dash forward", taBottom)
  elif sprite of TimeMachine:
    sprite.TimeMachine.use()
  elif sprite of Enemy:
    player.kill()
