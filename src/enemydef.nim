import rapid/world/sprite
import rapid/gfx

type
  EnemySprite* = enum
    esCircle = "circle"
    esTriangle = "triangle"
    esSquare = "square"
  EnemyMovement* = enum
    emLinearDown = "linearDown"
    emLinearUp = "linearUp"
    emLinearLeft = "linearLeft"
    emLinearRight = "linearRight"
  Enemy* = ref object of RSprite
    sprite*: EnemySprite
    movement*: EnemyMovement
    particles*: int

proc newEnemy*(x, y: float,
               sprite: EnemySprite, movement: EnemyMovement): Enemy =
  result = Enemy(
    pos: vec2(x, y),
    width: 8, height: 8,
    sprite: sprite,
    movement: movement
  )
  case movement
  of emLinearUp: result.vel = vec2(0.0, -1.0)
  of emLinearDown: result.vel = vec2(0.0, 1.0)
  of emLinearLeft: result.vel = vec2(-1.0, 0.0)
  of emLinearRight: result.vel = vec2(1.0, 0.0)
