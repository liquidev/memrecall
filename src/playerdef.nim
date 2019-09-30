import rapid/world/sprite
import rapid/gfx

import res

type
  Control* = enum
    ctrlJump
    ctrlFlip
    ctrlDash
  ControlEvent* = object
    control*: Control
    time*: float
    used*: bool
  PlayerDir* = enum
    pdLeft = -1
    pdRight = 1
  Player* = ref object of RSprite
    # Aux
    pvel*: Vec2[float]
    # Status
    atoms*, deaths*: int
    dead*: bool
    # Death
    deathTime*: float
    respawnPoint*: Vec2[float]
    # Controls - buffer
    controlBuffer*: seq[ControlEvent]
    # Controls - basic
    speed*: float
    jumpTime*: float
    # Controls - flip
    canFlip*, flipped*, hitFlipPlane*: bool
    # Controls - dash
    hasDash*, dashUsed*: bool
    dashEnd*: float
    dashDir*: PlayerDir
    dashDot*: Vec2[float]

proc expired*(ctrl: ControlEvent): bool = ctrl.used or time() - ctrl.time > 0.1

proc buffer(player: Player, ctrl: Control) =
  for ev in player.controlBuffer.mitems:
    if ev.expired:
      ev = ControlEvent(control: ctrl, time: time())
      return
  player.controlBuffer.add(ControlEvent(control: ctrl, time: time()))

proc init(player: Player) =
  win.onKeyPress do (key: Key, scancode: int, mods: RModKeys):
    if key == keyUp:
      player.buffer(ctrlJump)
    elif key == keyX:
      player.buffer(ctrlFlip)
    elif key == keyZ:
      player.buffer(ctrlDash)

proc newPlayer*(x, y: float): Player =
  result = Player(
    pos: vec2(x, y),
    width: 8, height: 8,
    respawnPoint: vec2(x, y),
    speed: 0.4,
    dashDot: vec2(x, y),
    dashDir: pdRight
  )
  result.init()
