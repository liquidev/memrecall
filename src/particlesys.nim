import rapid/gfx

type
  Particle* = object
    pos*, vel*: Vec2[float]
    decel*: float
    lifeEnd*: float
    color*: RColor
    dead: bool

var particles*: seq[Particle]

proc update*(particles: var seq[Particle]) =
  for p in particles.mitems:
    if not p.dead:
      p.pos += p.vel
      p.vel *= p.decel
      if time() > p.lifeEnd:
        p.dead = true

proc draw*(particles: seq[Particle], ctx: RGfxContext) =
  ctx.begin()
  for p in particles:
    if not p.dead:
      ctx.color = p.color
      ctx.point((p.pos.x, p.pos.y))
  ctx.draw(prPoints)

proc emit*(particles: var seq[Particle],
           pos, vel: Vec2[float], decel, life: float, color = gray(255)) =
  let
    t = time()
    part = Particle(pos: pos, vel: vel, decel: decel, lifeEnd: t + life,
                    color: color)
  for i, p in particles:
    if p.dead:
      particles[i] = part
      return
  particles.add(part)
