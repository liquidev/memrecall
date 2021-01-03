## This file is the heart of the game.
## If you're here, congratulations! This is your first step in improving the
## game – fixing a bug, adding a new feature, anything.
##
## I tried my best to keep the source code well-commented and easy to read.
## If you feel like there's some documentation missing, feel free to open a
## pull request.

import aglet
import rapid/game
import rapid/game/retro
import rapid/game/state_machine
import rapid/graphics
import rapid/input

import memrecall/game as mrcgame
import memrecall/game_load
import memrecall/state_play

proc main() =

  var g = Game()
  g.load()
  g.state.set(g.playState())

  runGameWhile not g.window.closeRequested:

    g.window.pollEvents proc (event: InputEvent) =
      g.input.process(event)

    update:
      g.state.current.update(g)
      g.input.finishTick()

    draw step:
      g.state.current.draw(g, step)

when isMainModule:
  main()
