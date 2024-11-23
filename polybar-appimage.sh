#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1

APP=polybar
REPO="https://github.com/polybar/polybar"
ICON="https://user-images.githubusercontent.com/36028424/39958898-230ddeec-563c-11e8-8318-d658c63ddf22.png"

UPINFO="gh-releases-zsync|$(echo $GITHUB_REPOSITORY | tr '/' '|')|latest|*$ARCH.AppImage.zsync"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"

# CREATE DIRECTORIES
mkdir -p ./"$APP"/AppDir
cd ./"$APP"/AppDir

# DOWNLOAD AND BUILD POLYBAR
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CXXFLAGS='-O3'

git clone --recursive "$REPO" polybar
( cd polybar
	mkdir build
	cd build
	cmake -DENABLE_ALSA=ON ..
	make -j$(nproc)
	make install DESTDIR="$CURRENTDIR"
)
rm -rf ./polybar

# ADD LIBRARIES
mkdir ./usr/lib
mv ./usr ./shared
wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
./lib4bin -p -v -r -s ./shared/bin/*
rm -f ./lib4bin

# Patch polybar binary so that it finds its default "/etc" config in the AppDir
sed -i 's|/etc|././|g' ./shared/bin/polybar
ln -s ./etc/polybar ./polybar

# AppRun
cat >> ./AppRun << 'EOF'
#!/usr/bin/env sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
export PATH="$CURRENTDIR/bin:$PATH"
BIN="${ARGV0#./}"
unset ARGV0
[ -z "$APPIMAGE" ] && APPIMAGE="$0"
[ ! -f "$CURRENTDIR/bin/$BIN" ] && BIN=polybar

# we patched a relative path in polybar, so we cd here
cd "$CURRENTDIR"

if [ "$1" = "--bars" ]; then
	shift
	for bar in "$@"; do
		exec "$CURRENTDIR/bin/polybar" "$bar" &
	done
elif [ "$1" = '--msg' ]; then
	shift
	exec "$CURRENTDIR"/bin/polybar-msg "$@"
else
	exec "$CURRENTDIR/bin/$BIN" "$@"
	echo "AppImage commands:"
	echo " \"$APPIMAGE --msg\"                 Launches polybar-msg"
	echo " \"$APPIMAGE --bars bar1 bar2 bar3\" Launches multiple bars"
	echo ""
	echo "You can also symlink the appimage with the name polybar-msg"
	echo "and by launching that symlink it will automatically run"
	echo "polybar-msg without having to pass any extra arguments"
	echo "AppImage also supports the \"--bars\" flag which lets you"
	echo "run multiple polybar instances with a single command"
fi
EOF
chmod +x ./AppRun
./sharun -g
VERSION="$(./bin/polybar --version | awk 'FNR==1 {print $2}')"

# Desktop
cat >> ./"$APP.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=polybar
Icon=polybar
Exec=polybar
Categories=System
Hidden=true
EOF

# Icon
wget "$ICON" -O ./polybar.png || touch ./polybar.png
ln -s polybar.png ./.DirIcon

# MAKE APPIMAGE USING FUSE3 COMPATIBLE APPIMAGETOOL
cd ..
wget -q "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

echo "Making appimage..."
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-anylinux-"$ARCH".AppImage

mv ./*.AppImage* ..
cd ..
rm -rf ./"$APP"
echo "All Done!"
