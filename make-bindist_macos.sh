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

# Launcher: user files go to data/ next to the .app; the game data folder is
# asked for once and then stored by 1oom in its config file.
cat > $APP/Contents/MacOS/1oom <<'LAUNCHER'
#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
APPDIR=$(cd "$HERE/../../.." && pwd)
USERDIR="$APPDIR/data"
mkdir -p "$USERDIR"
CFG="$USERDIR/1oom_config_game_classic_sdl2.txt"
DATAOPT=""
if ! grep -q '^opt.data_path = ' "$CFG" 2>/dev/null; then
    DATADIR=`osascript -e 'POSIX path of (choose folder with prompt "Select the folder with the Master of Orion (v1.3) files (*.LBX)")' 2>/dev/null`
    if [ -z "$DATADIR" ]; then
        exit 0
    fi
    DATAOPT="-data ${DATADIR%/}"
fi
cd "$USERDIR"
if [ -n "$DATAOPT" ]; then
    exec "$HERE/1oom_classic_sdl2" -user "$USERDIR" $DATAOPT "$@"
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
