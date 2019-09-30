import json
import math
import os
import streams
import strutils
import tables

import rapid/world/aabb
import rapid/world/tilemap
import rapid/gfx/text
import rapid/gfx
import yaml

import backgrounds
import enemydef
import particlesys
import playerdef
import powerups
import res
import state

type
  World* = RTmWorld[Tile]
  Level* = ref object
    title, hint: string
    background: Background
    hintPos: RTextVAlign
    color: RColor
    visited: bool
  Tile* = enum
    tileNone = " "
    tileSolid = "S"
    tileSpikes = "V"
    tileFlipPlaneH = "-"
    tileFlipPlaneV = "|"
    tileEnemyBarrier = "."

const SolidTiles* = {tileSolid}

proc defaultTile*(): Tile = tileNone
proc isSolid*(tile: Tile): bool = tile in SolidTiles
proc hitbox*(x, y: float, tile: Tile): RAABounds =
  newRAABB(x * 8, y * 8, 8, 8)

type
  YLevel = object
    title, tiles: string
    background: Background
    hint: YHint
    color: array[3, int]
    entities: seq[YEntity]
  YHint = object
    text: string
    pos: RTextVAlign
  YEntityKind = enum
    ePlayer = "player"
    eEnemy = "enemy"
    eCheckpoint = "checkpoint"
    eAtom = "atom"
    eFlipPack = "flipPack"
    eDashPack = "dashPack"
    eTimeMachine = "timeMachine"
  YEntity = object
    pos: array[2, float]
    kind: YEntityKind
    properties: Table[string, string]
setDefaultValue(YLevel, hint, YHint())
setDefaultValue(YLevel, background, bgNone)
setDefaultValue(YEntity, properties, initTable[string, string]())

proc loadLevel*(world: World, dx, dy: int, name: string): Level =
  var
    fs = newFileStream("data/levels"/(name & ".yaml"))
    yl: YLevel
  if fs == nil: quit("Level " & name & " doesn't exist")

  yaml.load(fs, yl)

  result = Level(
    title: yl.title,
    hint: yl.hint.text,
    hintPos: yl.hint.pos,
    background: yl.background,
    color: rgb(yl.color[0], yl.color[1], yl.color[2])
  )

  var y = 0
  for ln in yl.tiles.splitLines:
    for x, c in ln:
      world[dx + x, dy + y] = parseEnum[Tile]($c)
    inc(y)

  for ent in yl.entities:
    let pos = vec2(dx.float * 8 + ent.pos[0] * 8,
                   dy.float * 8 + ent.pos[1] * 8)
    case ent.kind
    of ePlayer:
      echo "adding player"
      world.add("player", newPlayer(pos.x, pos.y))
    of eCheckpoint:
      let cp = newCheckpoint(pos.x, pos.y)
      echo "checkpoint at ", name, ": ", cp.id
      world.add(cp)
    of eEnemy:
      world.add(newEnemy(pos.x, pos.y,
                         parseEnum[EnemySprite](ent.properties["sprite"]),
                         parseEnum[EnemyMovement](ent.properties["movement"])))
    of eAtom:
      world.add(newAtom(pos.x, pos.y))
    of eFlipPack:
      world.add(newFlipPack(pos.x, pos.y))
    of eDashPack:
      world.add(newDashPack(pos.x, pos.y))
    of eTimeMachine:
      world.add(newTimeMachine(pos.x, pos.y))

var
  world*: World
  levels*: Table[tuple[x, y: int], Level]
  currentLevel*: Level

proc drawWorld(ctx: RGfxContext, world: World, step: float) =
  let
    player = world["player"]
    lx = int (player.pos.x + 4) / 128
    ly = int (player.pos.y + 4) / 96
  currentLevel = levels[(lx, ly)]

  if not currentLevel.visited:
    setTitle(currentLevel.title)
    if currentLevel.hint != "":
      setHint(currentLevel.hint, currentLevel.hintPos)
    currentLevel.visited = true

  ctx.begin()
  var bgColor = currentLevel.color
  bgColor.alpha = 0.125
  ctx.color = bgColor
  ctx.rect(0, 0, mainCanvas.width, mainCanvas.height)
  ctx.color = gray(255)
  ctx.draw()

  drawBackground(currentLevel.background, currentLevel.color, ctx, step)

  ctx.transform:
    ctx.translate(-lx.float * 128, -ly.float * 96)
    ctx.begin()
    for x, y, t in world.area(lx * 16, ly * 12, 16, 12):
      case t
      of tileNone: discard
      of tileSolid:
        ctx.color = gray(0)
        ctx.rect(x.float * 8, y.float * 8, 8, 8)
      of tileSpikes:
        ctx.transform:
          ctx.translate(x.float * 8, y.float * 8)
          ctx.translate(4, 4)
          ctx.rotate(if world[x, y + 1].isSolid: 1.5 * PI
                     elif world[x, y - 1].isSolid: 0.5 * PI
                     elif world[x - 1, y].isSolid: 0.0
                     else: PI)
          ctx.color = gray(0)
          ctx.tri((-4.0, -4.0), (4.0, 0.0), (-4.0, 4.0))
      of tileFlipPlaneH:
        ctx.color = gray(255, 191)
        ctx.rect(x.float * 8, y.float * 8 + 3, 8, 1)
      of tileFlipPlaneV:
        ctx.color = gray(255, 191)
        ctx.rect(x.float * 8 + 3, y.float * 8, 1, 8)
      of tileEnemyBarrier: discard
    ctx.draw()
    ctx.clearStencil(0)
    ctx.stencil(saReplace, 255):
      ctx.draw()

    ctx.stencilTest = (scEq, 255)
    ctx.begin()
    ctx.color = currentLevel.color
    for x, y, t in world.area(lx * 16, ly * 12, 16, 12):
      let
        xf = x.float * 8
        yf = y.float * 8
      case t
      of tileNone: discard
      of tileSolid:
        if not world[x, y - 1].isSolid: ctx.rect(xf - 1, yf, 10, 1)
        if not world[x, y + 1].isSolid: ctx.rect(xf - 1, yf + 7, 10, 1)
        if not world[x - 1, y].isSolid: ctx.rect(xf, yf - 1, 1, 10)
        if not world[x + 1, y].isSolid: ctx.rect(xf + 7, yf - 1, 1, 10)
      of tileSpikes:
        ctx.transform:
          ctx.translate(x.float * 8, y.float * 8)
          ctx.translate(4, 4)
          ctx.rotate(if world[x, y + 1].isSolid: 1.5 * PI
                     elif world[x, y - 1].isSolid: 0.5 * PI
                     elif world[x - 1, y].isSolid: 0.0
                     else: PI)
          ctx.tri((-4.0, -4.0), (4.0, 0.0), (-4.0, 4.0))
      of tileFlipPlaneH, tileFlipPlaneV, tileEnemyBarrier: discard
    ctx.draw()
    ctx.noStencilTest()

    particles.draw(ctx)

    ctx.color = gray(255)
    world.drawSprites(ctx, step)

proc initWorld*() =
  var levelRefs: seq[seq[string]] =
    json.parseFile("data/world.json").to(seq[seq[string]])

  world = newRTmWorld[Tile](levelRefs[0].len * 16, levelRefs.len * 12, 8, 8)
  world.oobTile = tileSolid
  world.drawImpl = drawWorld
  world.implTile(initImpl = defaultTile,
                 isSolidImpl = isSolid,
                 hitboxImpl = hitbox)
  world.init()

  for y, r in levelRefs:
    for x, name in r:
      levels[(x, y)] = world.loadLevel(x * 16, y * 12, name)

  when not defined(release):
    let player = world["player"].Player
    if "c" in args:
      let id = parseInt(args["c"])
      echo "debug - starting at checkpoint ", id
      for ent in world.sprites:
        if ent of Checkpoint and ent.Checkpoint.id == id:
          player.pos = ent.pos
    if "f" in args:
      echo "debug - flip pack"
      player.canFlip = true
    if "d" in args:
      echo "debug - dash pack"
      player.hasDash = true
