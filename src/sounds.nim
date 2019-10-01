import os

import rapid/audio/device
import rapid/audio/sampler
import rapid/audio/samplers/mixer
import rapid/audio/samplers/wave

import usersettings

var
  audio*: RAudioDevice
  mix*: RMixer

type
  Music* = ref object of RSampler
    playing: bool
    start, loop: RWave
    volume: float

proc loadMusic*(start, loop: string): Music =
  result = Music(
    start: newRWave("data/music"/start, admStream),
    loop: newRWave("data/music"/loop, admStream)
  )
  result.loop.loop = true

proc play*(music: Music) =
  music.start.play()
  music.playing = true

proc stop*(music: Music) =
  music.playing = false

method sample*(music: Music, dest: var SampleBuffer, count: int) =
  if music.start.finished and not music.loop.playing:
    music.loop.play()
  if not music.start.finished:
    music.start.sample(dest, count)
  else:
    music.loop.sample(dest, count)
  for i in 0..<count:
    dest[i * 2] = dest[i * 2] * music.volume
    dest[i * 2 + 1] = dest[i * 2 + 1] * music.volume
    if music.playing and music.volume < 1:
      music.volume += 1 / 48000 / 2
    elif not music.playing and music.volume > 0:
      music.volume -= 1 / 48000 / 2
    music.volume = music.volume.clamp(0, 1)
  if music.volume == 0:
    music.start.stop()
    music.loop.stop()

var
  musicEscape*: Music
  musicEscapeT*: RTrack
  sndCheckpoint*, sndCollect*, sndCollect2*, sndDeath*, sndPlane*: RWave
  sndCheckpointT*, sndCollectT*, sndCollect2T*, sndDeathT*, sndPlaneT*: RTrack

proc playSound*(sound: RWave) =
  sound.stop()
  sound.play()

proc initSound*() =
  audio = newRAudioDevice("_MEM.RECALL()", latency = settings.audioLatency)
  mix = newRMixer()

  musicEscape = loadMusic("escape_start.ogg", "escape_loop.ogg")
  musicEscapeT = mix.add(musicEscape, volume = 0.6)

  const Snd = "data/sounds"
  sndCheckpoint = newRWave(Snd/"checkpoint.ogg")
  sndCollect = newRWave(Snd/"collect.ogg")
  sndCollect2 = newRWave(Snd/"collect_2.ogg")
  sndDeath = newRWave(Snd/"death.ogg")
  sndPlane = newRWave(Snd/"plane.ogg")
  sndCheckpointT = mix.add(sndCheckpoint)
  sndCollectT = mix.add(sndCollect)
  sndCollect2T = mix.add(sndCollect2)
  sndDeathT = mix.add(sndDeath)
  sndPlaneT = mix.add(sndPlane)

  audio.attach(mix)
  audio.start()
