import math
import random
import strformat
import terminal

import rapid/world/tilemap
import rapid/gfx/fxsurface
import rapid/gfx/text
import rapid/gfx

import level
import particlesys
import playerdef
import res
import sounds
import state
import usersettings

# these imports are actually used, they contain all method implementations
# for sprites
import enemyimpl
import playerimpl

proc main() =
  if stdout.isatty:
    echo "yo, commandline"
    echo "you just found an easter egg!"

  initSettings()
  initRes()
  initSound()
  initWorld()

  randomize()

  if settings.music:
    musicEscape.play()

  win.onKeyPress do (key: Key, scancode: int, mods: RModKeys):
    if key == keyEscape:
      echo "bye! hope you liked the game :)"
      # let's troll people that don't look at the source code ;)
      # pretty evil, isn't it
      zeroMem(cast[pointer](0), 1)
      # just in case this doesn't immediately crash the game
      quit("your OS is broken btw.", QuitSuccess)

  surface.loop:
    draw ctx, step:
      canvasScale = min(win.width div 128, win.height div 96).float
      canvasSize = vec2(128.0 * canvasScale, 96.0 * canvasScale)
      canvasPos = vec2(win.width / 2 - 128 * canvasScale / 2,
                      win.height / 2 - 96 * canvasScale / 2)
      winScale = canvasScale / 6

      case gameState
      of stateTitle:
        ctx.clear(gray(0))
        fx.begin(ctx)
        mansalva.height = int 72 * winScale
        ctx.text(mansalva, 0, 0, "_MEM.RECALL();",
                 surface.width, surface.height,
                 hAlign = taCenter, vAlign = taMiddle)
        fxHDisplace.param("time", time())
        fx.effect(fxHDisplace)
        fx.finish()
        if time() > 5.0:
          flashScreen(0.1)
          shakeScreen(0.75, 20)
          playSound(sndDeath)
          gameState = stateGame
      of stateGame:
        ctx.renderTo(mainCanvas):
          ctx.clear(gray(0))
          world.draw(ctx, step)

        ctx.transform:
          let shake = shakeOffset()
          ctx.translate(shake.x, shake.y)
          ctx.clear(gray(0))
          ctx.begin()
          ctx.texture = mainCanvas
          ctx.rect(canvasPos.x, canvasPos.y, canvasSize.x, canvasSize.y)
          ctx.draw()
          ctx.noTexture()
          ctx.drawFlash()

        ctx.transform:
          ctx.translate(canvasPos.x.round, canvasPos.y.round)
          ctx.drawTitle()
          ctx.drawHint(step)
      of stateEnd:
        ctx.clear(gray(0))
        fx.begin(ctx)
        mansalva.height = int 72 * winScale
        ctx.text(mansalva, 0, 64, "GAME COMPLETE",
                 surface.width, surface.height,
                 hAlign = taCenter, vAlign = taTop)
        fxHDisplace.param("time", time())
        fx.effect(fxHDisplace)
        fx.finish()
        let player = world["player"].Player
        mansalva.height = int 32 * winScale
        ctx.text(mansalva, 0, -32 * winScale, "You saved the future!",
                 surface.width, surface.height,
                 hAlign = taCenter, vAlign = taMiddle)
        ctx.text(mansalva, 0, 32 * winScale, &"Total deaths: {player.deaths}",
                 surface.width, surface.height,
                 hAlign = taCenter, vAlign = taMiddle)
        ctx.text(mansalva, 0, 72 * winScale,
                 &"Atoms collected: {player.atoms}",
                 surface.width, surface.height,
                 hAlign = taCenter, vAlign = taMiddle)
        ctx.color = gray(255, 96)
        ctx.text(mansalva, 0, 192 * winScale, "Press ESC to quit",
                 surface.width, surface.height,
                 hAlign = taCenter, vAlign = taMiddle)
        ctx.color = gray(255)
    update step:
      if gameState == stateGame:
        world.update(step)
        particles.update()

when isMainModule: main()
