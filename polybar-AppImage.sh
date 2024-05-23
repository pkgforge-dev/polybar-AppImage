#!/bin/sh

APP=polybar
APPDIR="$APP".AppDir
REPO="https://github.com/polybar/polybar"
ICON="https://user-images.githubusercontent.com/36028424/39958898-230ddeec-563c-11e8-8318-d658c63ddf22.png"
EXEC="$APP"

# CREATE DIRECTORIES
if [ -z "$APP" ]; then exit 1; fi
mkdir -p ./"$APP/$APPDIR" && cd ./"$APP/$APPDIR" || exit 1

# DOWNLOAD AND BUILD POLYBAR STATICALLY
CURRENTDIR="$(readlink -f "$(dirname "$0")")" # DO NOT MOVE THIS
CXXFLAGS='-static -O3' 
LDFLAGS="-static"

git clone --recursive "$REPO" && cd polybar && mkdir build && cd build && cmake -DENABLE_ALSA=ON .. \
&& make -j$(nproc) && make install DESTDIR="$CURRENTDIR" && cd ../.. || exit 1

# ADD LIBRARIES
mkdir ./usr/lib ./ & rm -rf ./polybar

# AppRun
cat >> ./AppRun << 'EOF'
#!/bin/bash
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
if [ "$1" = "msg" ]; then
	"$CURRENTDIR/usr/bin/polybar-msg" "${@:2}"
else
	/tmp/.*/usr/bin/polybar "$@" || "$CURRENTDIR/usr/bin/polybar" "$@"
fi
EOF
chmod a+x ./AppRun

APPVERSION=$(./AppRun --version | awk 'FNR == 1 {print $2}')

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
ln -s ./polybar.png ./.DirIcon

# MAKE APPIMAGE
LINUXDEPLOY="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-static-x86_64.AppImage"
cd .. && wget "$LINUXDEPLOY" -O linuxdeploy && chmod a+x ./linuxdeploy && ./linuxdeploy --appdir "$APPDIR" --executable "$APPDIR"/usr/bin/"$EXEC" --output appimage

# LIBFUSE3
APPIMAGETOOL=$(wget -q https://api.github.com/repos/probonopd/go-appimage/releases -O - | sed 's/"/ /g; s/ /\n/g' | grep -o 'https.*continuous.*tool.*86_64.*mage$')

[ -n "$APPDIR" ] && ls *AppImage && rm -rf ./"$APPDIR" || exit 1
./*AppImage --appimage-extract && mv ./squashfs-root ./"$APPDIR" && rm -f ./*AppImage && wget -q "$APPIMAGETOOL" -O ./appimagetool && chmod a+x ./appimagetool || exit 1

# Do the thing!
ARCH=x86_64 VERSION="$APPVERSION" ./appimagetool -s ./"$APPDIR" || exit 1
[ -n "$APP" ] && mv ./*.AppImage .. && cd .. && rm -rf ./"$APP" && echo "All Done!" || exit 1
