import glm

import math

proc dist*(a, b: Vec2[float]): float =
  let
    dx = b.x - a.x
    dy = b.y - a.y
  result = sqrt(dx * dx + dy * dy)
