1oom-osx: macOS port (fork)
===========================

This repository is a fork of [1oom-fork/1oom](https://github.com/1oom-fork/1oom) whose only goal is a
working build of 1oom on macOS (Apple Silicon), eventually packaged as an `.app` bundle. It changes build
glue (configure, Makefiles, bundling scripts), not the game logic.

Please read before using or contributing:

- **Made with AI assistance.** The macOS build work in this fork is done with the help of an AI coding
  assistant (Claude Code). The upstream project prohibits direct use of AI-generated code (see their note
  below), so this fork is **not affiliated with, endorsed by or supported by the upstream 1oom authors**,
  and nothing from here is meant to be submitted upstream. Please report macOS build issues here, not to
  upstream.
- **No game files are included.** 1oom is only an engine. The original Master of Orion (1993, v1.3) data
  files (`*.LBX` etc.) are copyrighted by MicroProse and are **not** part of this repository, of any
  release, `.app` bundle or ZIP from it. You must own a legal copy (for example the Steam release) and
  point 1oom at its folder with `-data <path>`.
- **Music.** The macOS bundle ships the General MIDI SoundFont `TimGM6mb.sf2` by Tim Brechbill and
  David Bolton (GPLv2, from MuseScore 1.3) so that the MIDI music plays; see [soundfont/README.md](soundfont/README.md).
- The original README, acknowledgements and the GPLv2 licence ([COPYING](COPYING)) follow unchanged.

Installing on macOS
-------------------

Requirements: a Mac with Apple Silicon (arm64), macOS 11 or newer, and your own copy of Master of
Orion v1.3 (for example the Steam release).

1. Download `1oom-<version>-macos-arm64.zip` from the [Releases](https://github.com/nozoku/1oom-osx/releases)
   page and unpack it. Put the folder wherever you like (for example `~/Applications/1oom`).
2. First start: right-click `1oom.app` and choose **Open**, then confirm. The app is not signed with an
   Apple Developer ID, so macOS asks once. Afterwards a normal double-click works.
3. Game files: if the Steam release of *Master of Orion 1* is installed, 1oom finds its files on its own.
   Otherwise a folder dialog asks for the folder that contains the game's `*.LBX` files (it must be the
   v1.3 data; `v11.lbx` must be present). The choice is saved in the configuration.
4. Saved games, the configuration and the log live in `data/` next to `1oom.app`. Nothing is written into
   the game folder or into system directories. Delete `data/` to start fresh.

Using
-----

- Controls, options and the in-game menus are documented in [doc/usage_classic.txt](doc/usage_classic.txt)
  and [doc/usage_common.txt](doc/usage_common.txt). Music plays in the intro, the main menu, battles,
  the council and other scenes; the star map is silent, as in the original.
- Command-line options can be appended when starting the launcher from a terminal:
  `1oom.app/Contents/MacOS/1oom -data /path/to/moo1` (other game folder),
  `-user /path` (other folder for saves and config), `-nomusic`, `-musicvol 0..128`,
  `-sdlmixersf FILE.sf2` (another SoundFont).
- The `data/1oom_log.txt` file is the first place to look when something does not work.
- Building from source: `brew install autoconf automake pkg-config sdl2_mixer libsamplerate cmake dylibbundler`,
  then `autoreconf -fi`, configure as described in [COMPILING](COMPILING) (on macOS add
  `--disable-hwalleg4` and the Homebrew include/lib paths), `make`, then in the build directory
  `sh ../build-deps_macos.sh` (builds FluidSynth without readline) and `make bindist` to produce the
  `.app` bundle (`make-bindist_macos.sh`).

Bundled libraries and licences
------------------------------

`1oom.app/Contents/libs` contains the libraries below; their licence texts are in
`1oom.app/Contents/Resources/licenses`. 1oom itself is GPLv2. The Master of Orion game files are not
included.

| Component | Version | Licence | Homepage |
|---|---|---|---|
| SDL2 (sdl2-compat) | 2.32.74 | zlib | https://github.com/libsdl-org/sdl2-compat |
| SDL3 | 3.4.18 | zlib | https://libsdl.org |
| SDL2_mixer | 2.8.2 | zlib | https://github.com/libsdl-org/SDL_mixer |
| libsamplerate | 0.2.2 | BSD-2-Clause | https://github.com/libsndfile/libsamplerate |
| FluidSynth (built from source without readline, libsndfile and audio drivers) | 2.6.1 | LGPL-2.1-or-later | https://www.fluidsynth.org |
| FLAC | 1.5.0 | BSD-3-Clause (library) | https://xiph.org/flac/ |
| libogg | 1.3.6 | BSD-3-Clause | https://www.xiph.org/ogg/ |
| libvorbis | 1.3.7 | BSD-3-Clause | https://xiph.org/vorbis/ |
| opus | 1.6.1 | BSD-3-Clause | https://www.opus-codec.org/ |
| opusfile | 0.12 | BSD-3-Clause | https://www.opus-codec.org/ |
| mpg123 | 1.33.7 | LGPL-2.1-only | https://www.mpg123.de/ |
| libxmp | 4.7.4 | LGPL-2.1-or-later | https://xmp.sourceforge.net/ |
| game-music-emu | 0.6.5 | LGPL-2.1-or-later | https://github.com/libgme/game-music-emu |
| WavPack | 5.9.0 | BSD-3-Clause | https://www.wavpack.com/ |
| TimGM6mb.sf2 (SoundFont) | MuseScore 1.3 | GPL-2 | see [soundfont/README.md](soundfont/README.md) |

The audio codec libraries come with SDL2_mixer from Homebrew; 1oom only uses the MIDI path
(FluidSynth with the bundled SoundFont). The Homebrew build of FluidSynth links readline (GPL-3), which
is not compatible with GPLv2, so the bundle uses a FluidSynth built by `build-deps_macos.sh` instead.

---

Upstream README
===============

This version of the game is no longer in development. Check out the vanilla branch to get an idea of ​​the latest engine version.

1oom
====

1oom aims to accurately reproduce the original DOS version of Master of Orion (1993) in a form that can be run on modern computers.
Direct use of AI-generated code is prohibited in 1oom. 1oom is Free Software (GPLv2), see [COPYING](COPYING).


1 Installation
===============

To use this software, you must legally own an original copy of Master of Orion (v1.3).
1oom requires a copy of the Master of Orion (v1.3) LBX files.
Please note that older saved games may not work in newer versions of 1oom.
Read the [changelog](CHANGES) to learn more about the breaking changes.

1.1 Windows, MSDOS
------------------

Simply extract the desired [release](https://github.com/1oom-fork/1oom/releases) to your MOO1 directory.
Alternatively copy your MOO1 LBX files (and saved games if needed) to your 1oom directory.
See [usage_common](doc/usage_common.txt) if you prefer to use a separate directory.

1.2 Unix (Linux)
----------------

1oom requires the following libraries:

- SDL (libsdl1.2 or libsdl2):
http://www.libsdl.org
- SDL_mixer (libsdl-mixer1.2 or libsdl2-mixer):
http://www.libsdl.org/projects/SDL_mixer/

Also recommended:

- libsamplerate:
http://www.mega-nerd.com/libsamplerate/

Check your distribution's package manager or the library
website on how to install them.

1.3 Android (DOSBox)
--------------------

To play on Android you will need the 1oom executable for MSDOS,
DOSBox application for Android and DPMI extension, for example
CWSDPMI. You can build the 1oom executable for MSDOS using i586
DJGPP and Allegro4.


2 Configuration
===============

See [usage_common](doc/usage_common.txt).


3 Development
=============

See [COMPILING](COMPILING) and [HACKING](HACKING) for more information.


4 Executables
=============

1oom consists of a few executables:

- [1oom_classic_*](doc/usage_classic.txt)    (the 1993 UI)
- [1oom_cmdline](doc/usage_cmdline.txt)      (proof of concept textual UI)
- [1oom_lbxview_*](doc/usage_lbxview.txt)    (for viewing LBX files)
- [1oom_lbxedit](doc/usage_lbxedit.txt)      (for editing LBX files)
- [1oom_pbxmake](doc/usage_pbxmake.txt)      (for creating PBX files)
- [1oom_pbxdump](doc/usage_pbxdump.txt)      (for dumping PBX files)
- [1oom_gfxconv](doc/usage_gfxconv.txt)      (for converting GFX for use in PBX files)
- [1oom_saveconv](doc/usage_saveconv.txt)     (for converting save game files)
- 1oom_*_sdl1       (using SDL 1.2.x)
- 1oom_*_sdl2       (using SDL 2.x)
- 1oom_*_alleg4     (using Allegro 4.x)

See [usage_common](doc/usage_common.txt) for common documentation.

Some ports have shorter filenames due to filesystem limitations.


5 Abbreviations
===============

The following abbreviations appear in the documentation and code:

- MOO1: Master of Orion 1 as represented by the v1.3 DOS binaries
- OSG: The Official Strategy Guide (ISBN 1-55958-507-2)


6 Acknowledgements
==================

Most of the credit for this software belongs to the progammer who authored
[1oom v1.0](https://kilgoretroutmaskreplicant.gitlab.io/plain-html) 
under the pseudonym Kilgore Trout Mask Replicant. Thank you for
creating this and publishing it free and open source!

Thanks to MyName aka Duzh87_54MSU for restoring 1oom from its broken state
and for creating [1oom v2.0 (vanilla)](https://sourcecraft.dev/fork1oom/1oom).

The original game Master of Orion was developed  by Simtex Software and
published 1993 by MicroProse. Thanks for the great game!

Thanks to Alan Emrich and Tom Hughes for documenting the game mechanics and AI
decision making in great detail in the official strategy guide.

Ideas and text snippets have been taken from kyrub's unofficial patch 1.40m
Readme. Thanks for the patch!

Thanks to [shikadi.net](http://www.shikadi.net) for documenting the
[music format](http://www.shikadi.net/wiki/modding/index.php?title=XMI_Format&oldid=6874).
https://moddingwiki.shikadi.net/wiki/XMI_Format

Thanks to CivFanatics forum user sargon0 for
[partial save game format info](http://forums.civfanatics.com/threads/moo-save-file-layout.275055/).

Special thanks to Zachary Kline (BlindGuyNW) for improving the text version of the game.

Thanks to those who contributed code, ideas or bug reports.

Some code has been pilfered from Chocolate Doom and VICE.

The files [HACKING](HACKING) and [PHILOSOPHY](PHILOSOPHY) are based on Chocolate Doom.
