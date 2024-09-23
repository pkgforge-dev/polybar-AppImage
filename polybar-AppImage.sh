#!/bin/sh
set -u
ARCH=x86_64
APP=polybar
APPDIR="$APP".AppDir
REPO="https://github.com/polybar/polybar"
ICON="https://user-images.githubusercontent.com/36028424/39958898-230ddeec-563c-11e8-8318-d658c63ddf22.png"
EXEC="$APP"

LINUXDEPLOY="https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20240109-1/linuxdeploy-static-x86_64.AppImage"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"

# CREATE DIRECTORIES
[ -n "$APP" ] && mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD POLYBAR STATICALLY
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CXXFLAGS='-O3'

git clone --recursive "$REPO" && cd polybar && mkdir build && cd build && cmake -DENABLE_ALSA=ON .. \
&& make -j$(nproc) && make install DESTDIR="$CURRENTDIR" && cd ../.. || exit 1

# ADD LIBRARIES
mkdir ./usr/lib ./ & rm -rf ./polybar

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
export PATH="$PATH:$CURRENTDIR/usr/bin"
BIN="$ARGV0"
unset ARGV0
case "$BIN" in
	'polybar'|'polybar-msg')
		exec "$CURRENTDIR/usr/bin/$BIN" "$@"
		;;

	*)
		if [ "$1" = '--msg' ]; then
			shift
			"$CURRENTDIR"/usr/bin/polybar-msg "$@"
		else
			"$CURRENTDIR"/usr/bin/polybar "$@"
			echo "AppImage command:"
			echo " \"$APPIMAGE --msg\"         Launches polybar-msg"
			echo "You can also symlink the appimage with the name polybar-msg"
			echo "and by launching that symlink it will automatically run"
			echo "polybar-msg without having to pass any extra arguments"
		fi
		;;
esac
EOF
chmod a+x ./AppRun
VERSION=$(./AppRun --version | awk 'FNR == 1 {print $2}')

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
export ARCH=x86_64
cd .. && wget "$LINUXDEPLOY" -O linuxdeploy && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./linuxdeploy ./appimagetool \
&& ./linuxdeploy --appdir "$APPDIR" --executable "$APPDIR"/usr/bin/"$EXEC" || exit 1
echo "Making appimage"
./appimagetool --comp zstd --mksquashfs-opt -Xcompression-level --mksquashfs-opt 20 ./"$APP".AppDir "$APP"-"$VERSION"-"$ARCH".AppImage

[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" && echo "All Done!" || exit 1
