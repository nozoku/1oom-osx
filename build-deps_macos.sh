#!/bin/sh

# build-deps_macos.sh: build the dependencies that the macOS .app bundle must
# not take from Homebrew. Run it from the build directory (e.g. build-native/)
# before "make bindist"; make-bindist_macos.sh picks the result up from deps/.
#
# FluidSynth (LGPL-2.1-or-later) is rebuilt without readline: the Homebrew
# build links readline (GPL-3), which cannot be combined with 1oom (GPL-2).
# The library is also built without libsndfile and without audio drivers,
# because SDL2_mixer only uses it as a MIDI synthesizer.
#
# Needs cmake (brew install cmake) and curl. Downloads the release tarball
# from GitHub (public resource); the SHA-256 is pinned below.

FLUIDSYNTH_VERSION=2.6.1
FLUIDSYNTH_SHA256=3d258a3bf97cc20c59eeebfe62c2432fae88adda74d3ad098681c76e0ebf446b
FLUIDSYNTH_URL=https://github.com/FluidSynth/fluidsynth/archive/refs/tags/v$FLUIDSYNTH_VERSION.tar.gz

DEPS=`pwd`/deps
SRC=$DEPS/src
PREFIX=$DEPS/fluidsynth

if ! command -v cmake >/dev/null 2>&1; then
    echo Error: cmake not found \(brew install cmake\)
    exit 1
fi

mkdir -p $SRC
TARBALL=$SRC/fluidsynth-$FLUIDSYNTH_VERSION.tar.gz
if [ ! -e $TARBALL ]; then
    curl -sL -o $TARBALL $FLUIDSYNTH_URL || exit 1
fi
GOT=`shasum -a 256 $TARBALL | cut -d' ' -f1`
if [ "$GOT" != "$FLUIDSYNTH_SHA256" ]; then
    echo Error: SHA-256 mismatch for $TARBALL
    echo "  expected $FLUIDSYNTH_SHA256"
    echo "  got      $GOT"
    exit 1
fi

rm -rf $SRC/fluidsynth-$FLUIDSYNTH_VERSION $SRC/fluidsynth-build $PREFIX
tar xzf $TARBALL -C $SRC || exit 1

cmake -S $SRC/fluidsynth-$FLUIDSYNTH_VERSION -B $SRC/fluidsynth-build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBUILD_SHARED_LIBS=ON \
    -Denable-framework=OFF \
    -Denable-readline=OFF \
    -Denable-libsndfile=OFF \
    -Denable-portaudio=OFF \
    -Denable-network=OFF \
    -Denable-ipv6=OFF \
    -Denable-dbus=OFF \
    -Denable-jack=OFF \
    -Denable-pulseaudio=OFF \
    -Denable-aufile=OFF \
    -Denable-coreaudio=OFF \
    -Denable-coremidi=OFF \
    -Denable-oss=OFF \
    -Denable-alsa=OFF \
    -Denable-sdl2=OFF \
    -Denable-sdl3=OFF \
    -Denable-openmp=OFF \
    > $SRC/fluidsynth-cmake.log 2>&1 || { echo Error: cmake configure failed, see $SRC/fluidsynth-cmake.log; exit 1; }
cmake --build $SRC/fluidsynth-build -j4 > $SRC/fluidsynth-build.log 2>&1 || { echo Error: build failed, see $SRC/fluidsynth-build.log; exit 1; }
cmake --install $SRC/fluidsynth-build > /dev/null 2>&1 || exit 1
cp $SRC/fluidsynth-$FLUIDSYNTH_VERSION/LICENSE $PREFIX/LICENSE

echo fluidsynth $FLUIDSYNTH_VERSION installed in $PREFIX
