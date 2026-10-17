# SoundFont for MIDI music on macOS

The Homebrew build of SDL2_mixer plays the game's MIDI music through FluidSynth, which needs a
General MIDI SoundFont. The macOS `.app` bundle therefore ships `TimGM6mb.sf2` and the launcher
points SDL_mixer at it (`SDL_SOUNDFONTS`) unless the 1oom configuration sets its own `sdlmixersf`.

`TimGM6mb.sf2` (5.97 MB)
- Copyright 2004 Tim Brechbill <https://www.timbrechbill.com>, 2010 David Bolton
- License: GNU General Public License version 2 (see `../COPYING`); the author states that the samples he
  did not create himself are public domain or GPL
- Origin: MuseScore 1.3 (https://github.com/musescore/musescore-old), obtained as the Debian source
  package `timgm6mb-soundfont` 1.3 from https://deb.debian.org/debian/pool/main/t/timgm6mb-soundfont/
  (MD5 of the .sf2: 1f1ad87ae6f87033d9a591eca567d919)

The game data files from Master of Orion are not part of this; see the top of the main README.
