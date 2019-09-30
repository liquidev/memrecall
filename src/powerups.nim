import math
import random

import rapid/world/sprite
import rapid/gfx/fxsurface
import rapid/gfx

import particlesys
import res
import sounds
import state

type
  Checkpoint* = ref object of RSprite
    id*: int
    particles: int
    collected*: bool

method draw*(cp: Checkpoint, ctx: RGfxContext, step: float) =
  ctx.transform:
    if not cp.collected:
      cfx.begin(ctx)
    ctx.translate(cp.pos.x + 4, cp.pos.y + 4)
    ctx.rotate(time() * (if cp.collected: 4.0 else: 1.5))
    ctx.clearStencil(255)
    ctx.stencil(saReplace, 0):
      ctx.begin()
      ctx.rect(-3, -3, 6, 6)
      ctx.draw()
    ctx.stencilTest = (scEq, 255)
    ctx.begin()
    ctx.rect(-4, -4, 8, 8)
    ctx.draw()
    ctx.noStencilTest()
    if not cp.collected:
      fxRgbSplit.param("offset", vec2f(sin(time() * 2) * 2, 0.0))
      cfx.effect(fxRgbSplit)
      cfx.finish()

method update*(cp: Checkpoint, step: float) =
  if cp.particles mod 10 == 0:
    for i in 0..1:
      let angle = time() * (if cp.collected: 4 else: 2) + i.float * PI
      particles.emit(pos = cp.pos + 4,
                     vel = vec2(cos(angle), sin(angle)) * 0.6,
                     decel = 0.95, life = 1)
  inc(cp.particles)

proc collect*(cp: Checkpoint) =
  playSound(sndCheckpoint)
  cp.collected = true
  for i in 0..<7:
    let angle = PI / 4 * i.float
    particles.emit(pos = cp.pos + 4,
                   vel = vec2(cos(angle), sin(angle)) * 2,
                   decel = 0.90, life = 0.3)

var checkpointID = 0

proc newCheckpoint*(x, y: float): Checkpoint =
  result = Checkpoint(
    pos: vec2(x, y),
    width: 8, height: 8,
    id: checkpointID
  )
  inc(checkpointID)

type
  Atom* = ref object of RSprite
    particles: int

proc collect*(atom: Atom) =
  flashScreen(0.05)
  shakeScreen(0.5, 20)
  playSound(sndCollect)
  for i in 0..<32:
    let angle = i / 32 * (PI * 2)
    particles.emit(pos = atom.pos + 4,
                   vel = vec2(cos(angle), sin(angle)) * 4,
                   decel = 0.9, life = 0.2 + i / 32)
  atom.delete = true

method draw*(atom: Atom, ctx: RGfxContext, step: float) =
  ctx.begin()
  ctx.circle(atom.pos.x + 4, atom.pos.y + 4 + sin(time()), 2)
  ctx.draw()

method update*(atom: Atom, step: float) =
  let
    angle0 = time() * PI * 2
    angle1 = -angle0 * 1.33
  if atom.particles mod 5 == 0:
    particles.emit(pos = atom.pos + 4 + vec2(cos(angle0), sin(angle0)) * 8,
                   vel = vec2(0.0),
                   decel = 1, life = 0.5)
  if atom.particles mod 5 == 2:
    particles.emit(pos = atom.pos + 4 + vec2(cos(angle1), sin(angle1)) * 4,
                   vel = vec2(0.0),
                   decel = 1, life = 0.3)
  inc(atom.particles)

proc newAtom*(x, y: float): Atom =
  result = Atom(
    pos: vec2(x, y),
    width: 8, height: 8
  )

type
  FlipPack* = ref object of RSprite
    particles: int

proc collect*(pack: FlipPack) =
  flashScreen(0.05)
  shakeScreen(0.5, 20)
  playSound(sndCollect)
  playSound(sndCollect2)
  for i in 0..<32:
    let angle = i / 32 * (PI * 2)
    particles.emit(pos = pack.pos + 4,
                   vel = vec2(cos(angle), sin(angle)) * 4,
                   decel = 0.9, life = 0.2 + i / 32)
  pack.delete = true

method draw*(pack: FlipPack, ctx: RGfxContext, step: float) =
  ctx.transform:
    ctx.translate(pack.pos.x, pack.pos.y)
    ctx.translate(4, 4)
    ctx.rotate(time())
    ctx.clearStencil(255)
    ctx.stencil(saReplace, 0):
      ctx.transform:
        ctx.rotate(0.2)
        ctx.begin()
        ctx.circle(0, 0, 3, 4)
        ctx.draw()
    ctx.stencilTest = (scEq, 255)
    ctx.begin()
    ctx.circle(0, 0, 6, 4)
    ctx.draw()
    ctx.noStencilTest()

method update*(pack: FlipPack, step: float) =
  if pack.particles mod 5 == 0:
    let angle = rand(0.0..2 * PI)
    particles.emit(pos = pack.pos + 4,
                  vel = vec2(cos(angle), sin(angle)) * rand(1.0..2.0),
                  decel = 0.9, life = 0.5)
  inc(pack.particles)

proc newFlipPack*(x, y: float): FlipPack =
  result = FlipPack(
    pos: vec2(x, y),
    width: 8, height: 8
  )

type
  DashPack* = ref object of RSprite
    particles: int

proc collect*(pack: DashPack) =
  flashScreen(0.05)
  shakeScreen(0.5, 20)
  playSound(sndCollect)
  playSound(sndCollect2)
  for i in 0..<32:
    let angle = i / 32 * (PI * 2)
    particles.emit(pos = pack.pos + 4,
                   vel = vec2(cos(angle), sin(angle)) * 4,
                   decel = 0.9, life = 0.2 + i / 32)
  pack.delete = true

method draw*(pack: DashPack, ctx: RGfxContext, step: float) =
  ctx.transform:
    ctx.translate(pack.pos.x, pack.pos.y)
    ctx.translate(4, 4)
    ctx.translate(0, sin(time() * 2.5))
    ctx.rotate(time())
    ctx.clearStencil(255)
    ctx.stencil(saReplace, 0):
      ctx.transform:
        ctx.rotate(0.2)
        ctx.begin()
        ctx.circle(0, 0, 3, 6)
        ctx.draw()
    ctx.stencilTest = (scEq, 255)
    ctx.begin()
    ctx.circle(0, 0, 6, 6)
    ctx.draw()
    ctx.noStencilTest()

method update*(pack: DashPack, step: float) =
  if pack.particles mod 5 == 0:
    let angle = rand(0.0..2 * PI)
    particles.emit(pos = pack.pos + 4,
                   vel = vec2(cos(angle), sin(angle)) * rand(1.0..2.0),
                   decel = 0.9, life = 0.5)
  if pack.particles mod 3 == 0:
    particles.emit(pos = pack.pos + 4 + vec2(0.0, sin(time() * 2.5) * 2) +
                         vec2(rand(-1.0..1.0), rand(-1.5..1.5)),
                   vel = vec2(-rand(1.5..2.0), 0.0),
                   decel = 0.95, life = 0.5)
  inc(pack.particles)

proc newDashPack*(x, y: float): DashPack =
  result = DashPack(
    pos: vec2(x, y),
    width: 8, height: 8
  )

type
  TimeMachine* = ref object of RSprite
    particles: int

proc use*(tm: TimeMachine) =
  flashScreen(0.05)
  shakeScreen(0.5, 20)
  playSound(sndCollect)
  playSound(sndDeath)
  gameState = stateEnd
  tm.delete = true

method draw*(tm: TimeMachine, ctx: RGfxContext, step: float) =
  ctx.transform:
    ctx.translate(tm.pos.x, tm.pos.y)
    ctx.translate(4, 4)
    ctx.translate(0, sin(time() * 2.5))
    ctx.rotate(time())
    ctx.clearStencil(255)
    ctx.stencil(saReplace, 0):
      ctx.transform:
        ctx.rotate(0.2)
        ctx.begin()
        ctx.circle(0, 0, 4, 12)
        ctx.draw()
    ctx.stencilTest = (scEq, 255)
    ctx.begin()
    ctx.circle(0, 0, 8, 12)
    ctx.draw()
    ctx.noStencilTest()

method update*(tm: TimeMachine, step: float) =
  if tm.particles mod 5 == 0:
    let angle = rand(0.0..2 * PI)
    particles.emit(pos = tm.pos + 4,
                    vel = vec2(cos(angle), sin(angle)) * rand(1.0..2.0),
                    decel = 0.9, life = 0.5)
  if tm.particles mod 3 == 0:
    let
      angleX = time() * 3
      angleY = time() * 3 + time()
    particles.emit(pos = tm.pos + 4 + vec2(cos(angleX), sin(angleY)) * 16,
                    vel = vec2(0.0),
                    decel = 0, life = 0.5)
  inc(tm.particles)

proc newTimeMachine*(x, y: float): TimeMachine =
  result = TimeMachine(
    pos: vec2(x, y),
    width: 8, height: 8
  )
