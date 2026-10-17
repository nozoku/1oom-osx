#!/bin/sh

# make-bindist_macos.sh: build a self-contained 1oom.app bundle on macOS.
# Called from "make bindist" / "make bindistzip" (see Makefile.am), like the
# win32 and msdos scripts. The Homebrew libraries the binary links against are
# copied into the bundle with dylibbundler (brew install dylibbundler).
#
# The Master of Orion game files are NOT included; the launcher asks for their
# folder on the first start and 1oom remembers it in its config file.

STRIP=$1
TOPSRCDIR=$2
ZIPKIND=$3

EXE=1oom_classic_sdl2

if [ ! -e src/$EXE ]; then
    echo Error: file src/$EXE not found, do a \"make\" first
    exit 1
fi

if ! command -v dylibbundler >/dev/null 2>&1; then
    echo Error: dylibbundler not found \(brew install dylibbundler\)
    exit 1
fi

if [ -e $TOPSRCDIR/.git ] && git -C $TOPSRCDIR describe --tags >/dev/null 2>&1; then
    VERSIONSTR=`git -C $TOPSRCDIR describe --tags`
else
    VERSIONSTR=v`sed -n 's/^AC_INIT(\[1oom\], *\[\([^]]*\)\].*/\1/p' $TOPSRCDIR/configure.ac`
fi
ARCH=`uname -m`

PACKAGESTR=1oom-$VERSIONSTR-macos-$ARCH
BINDISTDIR=$PACKAGESTR
ZIPNAME=$PACKAGESTR.zip
APP=$BINDISTDIR/1oom.app

rm -rf $BINDISTDIR
mkdir -p $APP/Contents/MacOS $APP/Contents/libs $BINDISTDIR/doc

cp src/$EXE $APP/Contents/MacOS/$EXE
$STRIP $APP/Contents/MacOS/$EXE

# Copy the dynamic libraries into the bundle and rewrite the load paths.
dylibbundler -od -b -x $APP/Contents/MacOS/$EXE -d $APP/Contents/libs/ -p @executable_path/../libs/ >/dev/null || exit 1

# Homebrew's SDL2 is sdl2-compat, which loads SDL3 at run time with dlopen
# ("@loader_path/libSDL3.dylib" first), so dylibbundler does not see it.
if [ -e $APP/Contents/libs/libSDL2-2.0.0.dylib ] && [ ! -e $APP/Contents/libs/libSDL3.dylib ]; then
    SDL3LIBDIR=`pkg-config --variable=libdir sdl3 2>/dev/null`
    if [ -n "$SDL3LIBDIR" ] && [ -e "$SDL3LIBDIR/libSDL3.0.dylib" ]; then
        cp "$SDL3LIBDIR/libSDL3.0.dylib" $APP/Contents/libs/libSDL3.dylib
        install_name_tool -id @loader_path/libSDL3.dylib $APP/Contents/libs/libSDL3.dylib 2>/dev/null
        codesign --force -s - $APP/Contents/libs/libSDL3.dylib 2>/dev/null
    else
        echo Warning: libSDL3 not found, the bundle will need SDL3 from Homebrew
    fi
fi

# Replace the Homebrew FluidSynth (links readline, GPL-3) with the one built by
# build-deps_macos.sh, then drop the libraries nothing references any more.
FLUIDLIB=deps/fluidsynth/lib/libfluidsynth.3.dylib
BUNDLED_FLUID=`ls $APP/Contents/libs/libfluidsynth*.dylib 2>/dev/null | head -1`
if [ -n "$BUNDLED_FLUID" ]; then
    if [ ! -e $FLUIDLIB ]; then
        echo Error: $FLUIDLIB not found, run "sh $TOPSRCDIR/build-deps_macos.sh" first
        exit 1
    fi
    cp $FLUIDLIB $BUNDLED_FLUID
    install_name_tool -id @executable_path/../libs/`basename $BUNDLED_FLUID` $BUNDLED_FLUID 2>/dev/null
    codesign --force -s - $BUNDLED_FLUID 2>/dev/null
    # prune: a library stays only while the executable or another library needs it
    # (otool -L prints a dylib's own install name first; skip that line)
    while :; do
        removed=no
        refs=`otool -L $APP/Contents/MacOS/$EXE | tail -n +2
              for l in $APP/Contents/libs/*.dylib; do otool -L $l | tail -n +3; done`
        for lib in $APP/Contents/libs/*.dylib; do
            name=`basename $lib`
            case $name in libSDL3.dylib) continue ;; esac
            if ! echo "$refs" | grep -q "/$name "; then
                rm -f $lib
                removed=yes
            fi
        done
        [ $removed = yes ] || break
    done
fi

# Licence texts of everything in the bundle (BSD/MIT/zlib require the notice
# to accompany binary distributions).
LICDIR=$APP/Contents/Resources/licenses
mkdir -p $LICDIR
cp $TOPSRCDIR/COPYING $LICDIR/1oom-COPYING.txt
cp $TOPSRCDIR/soundfont/README.md $LICDIR/TimGM6mb-README.md
cp deps/fluidsynth/LICENSE $LICDIR/fluid-synth-LICENSE.txt 2>/dev/null
for lib in $APP/Contents/libs/*.dylib; do
    name=`basename $lib`
    case $name in
        libSDL2-*) f=sdl2-compat ;;
        libSDL2_mixer*) f=sdl2_mixer ;;
        libSDL3*) f=sdl3 ;;
        libsamplerate*) f=libsamplerate ;;
        libfluidsynth*) continue ;;
        libmpg123*) f=mpg123 ;;
        libvorbis*) f=libvorbis ;;
        libogg*) f=libogg ;;
        libFLAC*) f=flac ;;
        libxmp*) f=libxmp ;;
        libportaudio*) f=portaudio ;;
        libreadline*) f=readline ;;
        libmp3lame*) f=lame ;;
        libwavpack*) f=wavpack ;;
        libsndfile*) f=libsndfile ;;
        libopusfile*) f=opusfile ;;
        libgme*) f=game-music-emu ;;
        libopus*) f=opus ;;
        *) echo Warning: no licence mapping for $name; continue ;;
    esac
    found=no
    for lic in `find /opt/homebrew/opt/$f/ -maxdepth 1 -type f \( -iname 'LICENSE*' -o -iname 'COPYING*' \) 2>/dev/null`; do
        cp "$lic" $LICDIR/$f-`basename "$lic"`
        found=yes
    done
    [ $found = yes ] || echo Warning: no licence file found for $f \(see THIRD-PARTY.txt\)
done
cat > $LICDIR/THIRD-PARTY.txt <<'THIRDPARTY'
Third-party components in this bundle (Contents/libs and Contents/Resources)

  SDL2 (sdl2-compat), SDL3, SDL2_mixer   zlib licence       https://libsdl.org
  libsamplerate                          BSD-2-Clause       https://github.com/libsndfile/libsamplerate
  FluidSynth (built without readline)    LGPL-2.1-or-later  https://www.fluidsynth.org
  libogg, libvorbis, opus, opusfile      BSD-3-Clause       https://xiph.org
  FLAC                                   BSD-3-Clause (library), GPL-2+ (tools)  https://xiph.org/flac/
  mpg123                                 LGPL-2.1           https://www.mpg123.de
  libxmp                                 LGPL-2.1-or-later  https://xmp.sourceforge.net
  game-music-emu                         LGPL-2.1-or-later  https://github.com/libgme/game-music-emu
  WavPack                                BSD-3-Clause       https://www.wavpack.com
  TimGM6mb.sf2 (SoundFont)               GPL-2              Tim Brechbill, David Bolton (MuseScore 1.3)

The licence texts shipped by the respective packages are in this folder. Only the
libraries actually present in Contents/libs apply to this build. 1oom itself is GPL-2
(1oom-COPYING.txt). The Master of Orion game files are not included.
THIRDPARTY

# General MIDI SoundFont for the music (see soundfont/README.md).
mkdir -p $APP/Contents/Resources
cp $TOPSRCDIR/soundfont/TimGM6mb.sf2 $APP/Contents/Resources/TimGM6mb.sf2

# Launcher: user files go to data/ next to the .app; the game data folder is
# asked for once and then stored by 1oom in its config file; the bundled
# SoundFont is used unless the config names its own (sdlmixersf).
cat > $APP/Contents/MacOS/1oom <<'LAUNCHER'
#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
APPDIR=$(cd "$HERE/../../.." && pwd)
USERDIR="$APPDIR/data"
mkdir -p "$USERDIR"
CFG="$USERDIR/1oom_config_game_classic_sdl2.txt"
DATADIR=""
STEAMDIR="$HOME/Library/Application Support/Steam/steamapps/common/Master of Orion 1/Master Of Orion.app/Contents/Resources/Master Of Orion.boxer/C.harddisk"
if ! grep -q '^opt.data_path = ' "$CFG" 2>/dev/null; then
    if [ -e "$STEAMDIR/v11.lbx" ]; then
        DATADIR="$STEAMDIR"
    else
        DATADIR=`osascript -e 'POSIX path of (choose folder with prompt "Select the folder with the Master of Orion (v1.3) files (*.LBX)")' 2>/dev/null`
        if [ -z "$DATADIR" ]; then
            exit 0
        fi
    fi
    DATADIR="${DATADIR%/}"
fi
if ! grep -qE '^[a-z.]*sdlmixersf = ' "$CFG" 2>/dev/null; then
    SDL_SOUNDFONTS="$HERE/../Resources/TimGM6mb.sf2"
    export SDL_SOUNDFONTS
fi
cd "$USERDIR"
if [ -n "$DATADIR" ]; then
    exec "$HERE/1oom_classic_sdl2" -user "$USERDIR" -data "$DATADIR" "$@"
else
    exec "$HERE/1oom_classic_sdl2" -user "$USERDIR" "$@"
fi
LAUNCHER
chmod +x $APP/Contents/MacOS/1oom

cat > $APP/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>1oom</string>
    <key>CFBundleDisplayName</key>
    <string>1oom</string>
    <key>CFBundleIdentifier</key>
    <string>com.github.nozoku.1oom-osx</string>
    <key>CFBundleVersion</key>
    <string>$VERSIONSTR</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSIONSTR</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>1oom</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo $PACKAGESTR > $BINDISTDIR/1version.txt
cp $TOPSRCDIR/doc/*.txt $BINDISTDIR/doc
cp $TOPSRCDIR/README.md $BINDISTDIR/1README.txt
cp $TOPSRCDIR/COPYING $BINDISTDIR/1COPYING.txt

if [ -e extrabindist_common ]; then
    cp extrabindist_common/* $BINDISTDIR
fi

if [ -e extrabindist_macos ]; then
    cp extrabindist_macos/* $BINDISTDIR
fi

if test x"$ZIPKIND" = "xzip"; then
    ditto -c -k --sequesterRsrc --keepParent $BINDISTDIR $ZIPNAME || exit 1
    echo zip $ZIPNAME created
    rm -f -r $BINDISTDIR
else
    echo dir $BINDISTDIR created
fi
